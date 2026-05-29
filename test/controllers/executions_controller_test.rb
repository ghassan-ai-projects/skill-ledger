require "test_helper"

class Api::V1::ExecutionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = accounts(:alice)
    @bob = accounts(:bob)
    @charlie = accounts(:charlie)
    @data_analysis = skills(:data_analysis)
    @code_review = skills(:code_review)
    @execution = executions(:execution_one)
  end

  # ── Execute (create) ───────────────────────────────────────────

  test "POST /api/v1/skills/:id/execute executes a skill successfully" do
    assert_difference("Execution.count", 1) do
      assert_difference -> { @charlie.reload.balance }, -@data_analysis.price_per_call do
        assert_difference -> { @alice.reload.balance }, @data_analysis.price_per_call do
          post api_v1_execute_skill_url(@data_analysis), params: { buyer_id: @charlie.id }, as: :json
        end
      end
    end
    assert_response :created

    body = response.parsed_body
    assert_equal "completed", body["status"]
    assert_equal @data_analysis.id, body["skill_id"]
    assert_equal @charlie.id, body["buyer_id"]
  end

  test "POST /api/v1/skills/:id/execute creates a ledger entry" do
    assert_difference("LedgerEntry.count", 1) do
      post api_v1_execute_skill_url(@data_analysis), params: { buyer_id: @charlie.id }, as: :json
    end
    assert_response :created

    entry = LedgerEntry.last
    assert_equal @charlie.id, entry.from_account_id
    assert_equal @alice.id, entry.to_account_id
    assert_equal @data_analysis.price_per_call.to_s, entry.amount.to_s
    assert_equal "skill_execution", entry.entry_type
  end

  test "POST /api/v1/skills/:id/execute returns error when buyer not found" do
    assert_no_difference(["Execution.count", "LedgerEntry.count"]) do
      post api_v1_execute_skill_url(@data_analysis), params: { buyer_id: 99999 }, as: :json
    end
    assert_response :unprocessable_entity
    assert_includes response.parsed_body["error"], "Buyer not found"
  end

  test "POST /api/v1/skills/:id/execute returns error when buyer has insufficient balance" do
    expensive_skill = Skill.create!(
      name: "Expensive Skill",
      author: @alice,
      price_per_call: 999.00,
      stake_amount: 10.00
    )

    assert_no_difference(["Execution.count", "LedgerEntry.count"]) do
      post api_v1_execute_skill_url(expensive_skill), params: { buyer_id: @charlie.id }, as: :json
    end
    assert_response :unprocessable_entity
    assert_includes response.parsed_body["error"], "Buyer has insufficient balance"
  end

  test "POST /api/v1/skills/:id/execute returns error when buyer is the author" do
    assert_no_difference(["Execution.count", "LedgerEntry.count"]) do
      post api_v1_execute_skill_url(@data_analysis), params: { buyer_id: @alice.id }, as: :json
    end
    assert_response :unprocessable_entity
    assert_includes response.parsed_body["error"], "Cannot execute your own skill"
  end

  test "POST /api/v1/skills/:id/execute returns 404 for missing skill" do
    assert_no_difference(["Execution.count", "LedgerEntry.count"]) do
      post api_v1_execute_skill_url(skill_id: 99999), params: { buyer_id: @charlie.id }, as: :json
    end
    assert_response :not_found
    assert response.parsed_body.key?("error")
    assert response.parsed_body.key?("details")
  end

  # ── Index ──────────────────────────────────────────────────────

  test "GET /api/v1/executions returns all executions" do
    get api_v1_executions_url
    assert_response :success

    body = response.parsed_body
    assert_equal 1, body.length
    assert_equal "completed", body[0]["status"]
  end

  test "GET /api/v1/executions includes skill and buyer info" do
    get api_v1_executions_url
    assert_response :success

    exec = response.parsed_body.first
    assert_not_nil exec["skill"]
    assert_equal @data_analysis.id, exec["skill"]["id"]
    assert_equal "Data Analysis", exec["skill"]["name"]

    assert_not_nil exec["buyer"]
    assert_equal @bob.id, exec["buyer"]["id"]
    assert_equal "Bob", exec["buyer"]["name"]
  end

  test "GET /api/v1/executions includes execution after buying a skill" do
    post api_v1_execute_skill_url(@data_analysis), params: { buyer_id: @charlie.id }, as: :json
    assert_response :created

    get api_v1_executions_url
    assert_response :success
    assert_equal 2, response.parsed_body.length
  end

  test "GET /api/v1/executions filters by skill_id" do
    # Execute the other skill too
    post api_v1_execute_skill_url(@code_review), params: { buyer_id: @charlie.id }, as: :json
    assert_response :created

    # Filter by data_analysis skill
    get api_v1_executions_url(skill_id: @data_analysis.id)
    assert_response :success
    body = response.parsed_body
    assert_equal 1, body.length
    assert_equal @data_analysis.id, body[0]["skill_id"]
  end

  test "GET /api/v1/executions returns empty when no executions match skill_id filter" do
    get api_v1_executions_url(skill_id: 99999)
    assert_response :success
    assert_equal [], response.parsed_body
  end

  test "GET /api/v1/executions returns empty when no executions exist" do
    Execution.delete_all

    get api_v1_executions_url
    assert_response :success
    assert_equal [], response.parsed_body
  end

  # ── Fail (Slash + Refund) ─────────────────────────────────────

  test "fail slashes stake and refunds buyer" do
    assert_difference("LedgerEntry.count", 2) do
      assert_difference -> { @alice.reload.balance }, -(@data_analysis.stake_amount + @data_analysis.price_per_call) do
        assert_difference -> { @bob.reload.balance }, @data_analysis.stake_amount + @data_analysis.price_per_call do
          patch fail_api_v1_execution_url(@execution)
        end
      end
    end
    assert_response :ok

    @execution.reload
    assert_equal "failed", @execution.status

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

  test "fail returns error when execution already failed" do
    patch fail_api_v1_execution_url(@execution)
    assert_response :ok

    assert_no_difference("LedgerEntry.count") do
      patch fail_api_v1_execution_url(@execution)
    end
    assert_response :unprocessable_entity
    assert_includes response.parsed_body["error"], "already failed"
  end

  test "fail returns 404 for missing execution" do
    assert_no_difference(["LedgerEntry.count", "Execution.where(status: 'failed').count"]) do
      patch fail_api_v1_execution_url(id: 99999)
    end
    assert_response :not_found
    assert_includes response.parsed_body["error"], "Couldn't find Execution"
    assert_equal [], response.parsed_body["details"]
  end

  test "fail returns error when author has insufficient balance" do
    @alice.update!(balance: 0)

    assert_no_difference(["LedgerEntry.count", "Execution.where(status: 'failed').count"]) do
      patch fail_api_v1_execution_url(@execution)
    end
    assert_response :unprocessable_entity
    assert_includes response.parsed_body["error"], "Validation failed"
    assert response.parsed_body["details"].any?
  end
end
