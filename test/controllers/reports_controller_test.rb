require "test_helper"

class Api::V1::ReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = accounts(:alice)
    @bob = accounts(:bob)
    @data_analysis = skills(:data_analysis)
  end

  test "GET /api/v1/reports returns correct stats" do
    get api_v1_reports_url, headers: headers_with_auth(@alice)
    assert_response :success

    body = response.parsed_body
    assert_equal 2, body["total_skills"]
    assert_equal 2, body["total_executions"]
    assert_equal 2, body["completed_executions"]
    assert_equal 0, body["failed_executions"]
    assert_equal 0, body["total_slashed"]
    # Alice: 1000, Bob: 500, Charlie: 250 = 1750
    assert_equal 1750.0, body["total_ledger_balance"]
  end

  test "GET /api/v1/reports updates after execution and fail" do
    post api_v1_execute_skill_url(@data_analysis),
         params: { buyer_id: @bob.id },
         headers: headers_with_auth(@alice), as: :json
    assert_response :created

    get api_v1_reports_url, headers: headers_with_auth(@alice)
    body = response.parsed_body
    assert_equal 3, body["total_executions"]
    assert_equal 3, body["completed_executions"]
    assert_equal 0, body["failed_executions"]

    execution = Execution.last
    patch fail_api_v1_execution_url(execution), headers: headers_with_auth(@alice)

    get api_v1_reports_url, headers: headers_with_auth(@alice)
    body = response.parsed_body
    assert_equal 3, body["total_executions"]
    assert_equal 2, body["completed_executions"]
    assert_equal 1, body["failed_executions"]
    assert_equal @data_analysis.stake_amount.to_f, body["total_slashed"]
  end

  test "GET /api/v1/reports includes slashed amounts after fail" do
    post api_v1_execute_skill_url(@data_analysis),
         params: { buyer_id: @bob.id },
         headers: headers_with_auth(@alice), as: :json
    execution = Execution.last
    patch fail_api_v1_execution_url(execution), headers: headers_with_auth(@alice)

    get api_v1_reports_url, headers: headers_with_auth(@alice)
    assert_equal @data_analysis.stake_amount.to_f, response.parsed_body["total_slashed"]
  end
end
