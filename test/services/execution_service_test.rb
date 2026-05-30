require "test_helper"

class ExecutionServiceTest < ActiveSupport::TestCase
  setup do
    @alice = accounts(:alice)
    @bob = accounts(:bob)
    @charlie = accounts(:charlie)
    @data_analysis = skills(:data_analysis)
    @code_review = skills(:code_review)
    @execution = executions(:execution_one)
  end

  # ── Create ─────────────────────────────────────────────────────

  test "creates an execution successfully" do
    service = ExecutionService.new

    assert_difference("Execution.count", 1) do
      assert_difference -> { @charlie.reload.balance }, -@data_analysis.price_per_call do
        assert_difference -> { @alice.reload.balance }, @data_analysis.price_per_call do
          execution = service.create(skill_id: @data_analysis.id, buyer_id: @charlie.id)
          assert_equal "completed", execution.status
          assert_equal @data_analysis.id, execution.skill_id
          assert_equal @charlie.id, execution.buyer_id
        end
      end
    end
  end

  test "creates a ledger entry on execution" do
    service = ExecutionService.new

    assert_difference("LedgerEntry.count", 1) do
      service.create(skill_id: @data_analysis.id, buyer_id: @charlie.id)
    end

    entry = LedgerEntry.last
    assert_equal @charlie.id, entry.from_account_id
    assert_equal @alice.id, entry.to_account_id
    assert_equal @data_analysis.price_per_call.to_s, entry.amount.to_s
    assert_equal "skill_execution", entry.entry_type
  end

  test "raises error when buyer not found" do
    service = ExecutionService.new
    assert_raises ExecutionService::Error, match: "Buyer not found" do
      service.create(skill_id: @data_analysis.id, buyer_id: 99999)
    end
  end

  test "raises error when buyer has insufficient balance" do
    expensive_skill = Skill.create!(name: "Expensive Skill", author: @alice, price_per_call: 999.00, stake_amount: 10.00)
    service = ExecutionService.new

    assert_raises ExecutionService::Error, match: "Buyer has insufficient balance" do
      service.create(skill_id: expensive_skill.id, buyer_id: @charlie.id)
    end
  end

  test "raises error when buyer is the author" do
    service = ExecutionService.new
    assert_raises ExecutionService::Error, match: "Cannot execute your own skill" do
      service.create(skill_id: @data_analysis.id, buyer_id: @alice.id)
    end
  end

  test "raises error for missing skill" do
    service = ExecutionService.new
    assert_raises ActiveRecord::RecordNotFound do
      service.create(skill_id: 99999, buyer_id: @charlie.id)
    end
  end

  # ── Fail ───────────────────────────────────────────────────────

  test "fail slashes stake and refunds buyer" do
    service = ExecutionService.new

    assert_difference("LedgerEntry.count", 2) do
      assert_difference -> { @alice.reload.balance }, -(@data_analysis.stake_amount + @data_analysis.price_per_call) do
        assert_difference -> { @bob.reload.balance }, @data_analysis.stake_amount + @data_analysis.price_per_call do
          execution = service.fail(execution_id: @execution.id)
          assert_equal "failed", execution.status
        end
      end
    end

    slash_entry = LedgerEntry.find_by(entry_type: "slash")
    assert_not_nil slash_entry
    assert_equal @alice.id, slash_entry.from_account_id
    assert_equal @bob.id, slash_entry.to_account_id
    assert_equal @data_analysis.stake_amount.to_s, slash_entry.amount.to_s

    refund_entry = LedgerEntry.find_by(entry_type: "refund")
    assert_not_nil refund_entry
    assert_equal @alice.id, refund_entry.from_account_id
    assert_equal @bob.id, refund_entry.to_account_id
    assert_equal @data_analysis.price_per_call.to_s, refund_entry.amount.to_s
  end

  test "raises error when execution already failed" do
    service = ExecutionService.new
    service.fail(execution_id: @execution.id)

    assert_raises ExecutionService::Error, match: "already failed" do
      service.fail(execution_id: @execution.id)
    end
  end

  test "raises error for missing execution on fail" do
    service = ExecutionService.new
    assert_raises ActiveRecord::RecordNotFound do
      service.fail(execution_id: 99999)
    end
  end

  test "raises error when author has insufficient balance for fail" do
    @alice.update!(balance: 0)
    service = ExecutionService.new

    assert_raises ActiveRecord::RecordInvalid do
      service.fail(execution_id: @execution.id)
    end
  end
end
