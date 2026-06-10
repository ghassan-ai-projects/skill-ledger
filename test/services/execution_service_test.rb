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
        assert_difference -> { @charlie.reload.escrow_balance }, @data_analysis.price_per_call do
          execution = service.create(skill_id: @data_analysis.id, buyer_id: @charlie.id)
          assert_equal "pending", execution.status
          assert_equal @data_analysis.id, execution.skill_id
          assert_equal @charlie.id, execution.buyer_id
        end
      end
    end
  end

  test "does not create a ledger entry while execution is pending in escrow" do
    service = ExecutionService.new

    assert_no_difference("LedgerEntry.count") do
      service.create(skill_id: @data_analysis.id, buyer_id: @charlie.id)
    end
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

  # ── Complete ───────────────────────────────────────────────────

  test "complete releases escrow exactly once and marks execution completed" do
    service = ExecutionService.new
    execution = service.create(skill_id: @data_analysis.id, buyer_id: @charlie.id)

    assert_difference("LedgerEntry.count", 1) do
      assert_difference -> { @charlie.reload.balance }, 0 do
        assert_difference -> { @charlie.reload.escrow_balance }, -@data_analysis.price_per_call do
          assert_difference -> { @alice.reload.balance }, @data_analysis.price_per_call do
            completed = service.complete(execution_id: execution.id)
            assert_equal "completed", completed.status
          end
        end
      end
    end

    entry = LedgerEntry.last
    assert_equal @charlie.id, entry.from_account_id
    assert_equal @alice.id, entry.to_account_id
    assert_equal @data_analysis.price_per_call.to_s, entry.amount.to_s
    assert_equal "skill_execution", entry.entry_type
  end

  test "complete rejects non-pending execution" do
    service = ExecutionService.new

    assert_raises ExecutionService::Error, match: "not pending" do
      service.complete(execution_id: @execution.id)
    end
  end

  # ── Fail ───────────────────────────────────────────────────────

  test "fail slashes locked stake and refunds buyer from escrow" do
    service = ExecutionService.new
    @alice.update!(balance: @alice.balance - @data_analysis.stake_amount, locked_stake: @data_analysis.stake_amount)
    pending_execution = service.create(skill_id: @data_analysis.id, buyer_id: @bob.id)

    assert_difference("LedgerEntry.count", 1) do
      assert_difference -> { @alice.reload.locked_stake }, -@data_analysis.stake_amount do
        assert_difference -> { @bob.reload.escrow_balance }, -@data_analysis.price_per_call do
          assert_difference -> { @bob.reload.balance }, @data_analysis.stake_amount + @data_analysis.price_per_call do
            execution = service.fail(execution_id: pending_execution.id)
            assert_equal "failed", execution.status
          end
        end
      end
    end

    slash_entry = LedgerEntry.find_by(entry_type: "slash")
    assert_not_nil slash_entry
    assert_equal @alice.id, slash_entry.from_account_id
    assert_equal @bob.id, slash_entry.to_account_id
    assert_equal @data_analysis.stake_amount.to_s, slash_entry.amount.to_s
  end

  test "fail rejects non-pending execution" do
    service = ExecutionService.new

    assert_raises ExecutionService::Error, match: "not pending" do
      service.fail(execution_id: @execution.id)
    end
  end

  test "fail rejects already failed execution" do
    service = ExecutionService.new
    @alice.update!(balance: @alice.balance - @data_analysis.stake_amount, locked_stake: @data_analysis.stake_amount)
    pending_execution = service.create(skill_id: @data_analysis.id, buyer_id: @bob.id)
    service.fail(execution_id: pending_execution.id)

    assert_raises ExecutionService::Error, match: "already failed" do
      service.fail(execution_id: pending_execution.id)
    end
  end

  test "fail rejects when locked stake is insufficient" do
    service = ExecutionService.new
    pending_execution = service.create(skill_id: @data_analysis.id, buyer_id: @bob.id)

    assert_raises ExecutionService::Error, match: "locked stake" do
      service.fail(execution_id: pending_execution.id)
    end
  end

  test "complete raises error for missing execution" do
    service = ExecutionService.new

    assert_raises ActiveRecord::RecordNotFound do
      service.complete(execution_id: 99999)
    end
  end

  test "fail raises error for missing execution" do
    service = ExecutionService.new
    assert_raises ActiveRecord::RecordNotFound do
      service.fail(execution_id: 99999)
    end
  end

  test "create keeps escrow and balance invariant when execution is pending" do
    service = ExecutionService.new

    execution = service.create(skill_id: @data_analysis.id, buyer_id: @charlie.id)

    assert_equal "pending", execution.status
    assert_equal @data_analysis.price_per_call.to_d, @charlie.reload.escrow_balance
    assert_equal 0.to_d, @alice.reload.escrow_balance
  end
end
