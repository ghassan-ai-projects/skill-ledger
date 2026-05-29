require "test_helper"

class Api::V1::AnalyticsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = accounts(:alice)
    @bob = accounts(:bob)
    @charlie = accounts(:charlie)
    @data_analysis = skills(:data_analysis)  # Alice's skill
    @code_review = skills(:code_review)       # Bob's skill
  end

  # ── Analytics Show ────────────────────────────────────────────

  test "GET /api/v1/authors/:id/analytics returns analytics for own account" do
    get analytics_api_v1_author_url(@alice), headers: headers_with_auth(@alice)
    assert_response :success

    body = response.parsed_body
    assert_equal @alice.id, body["author"]["id"]
    assert_equal "Alice", body["author"]["name"]
    assert_equal 1, body["total_skills"]      # Alice has data_analysis
    assert_equal 1, body["total_executions"]  # execution_one for data_analysis
    assert body.key?("total_earnings")
    assert body.key?("total_slashed")
    assert body.key?("execution_breakdown")
    assert body.key?("top_skills")
    assert body.key?("recent_executions")
  end

  test "GET /api/v1/authors/:id/analytics returns 403 for another author's data" do
    get analytics_api_v1_author_url(@alice), headers: headers_with_auth(@bob)
    assert_response :forbidden
    assert_includes response.parsed_body["error"], "You can only access your own analytics"
  end

  test "GET /api/v1/authors/:id/analytics returns 404 for non-existent author" do
    get analytics_api_v1_author_url(id: 99999), headers: headers_with_auth(@alice)
    assert_response :not_found
  end

  test "GET /api/v1/authors/:id/analytics includes execution_breakdown" do
    get analytics_api_v1_author_url(@alice), headers: headers_with_auth(@alice)
    assert_response :success

    breakdown = response.parsed_body["execution_breakdown"]
    assert breakdown.key?("completed")
    assert breakdown.key?("failed")
    assert breakdown.key?("pending")
  end

  test "GET /api/v1/authors/:id/analytics includes top_skills" do
    get analytics_api_v1_author_url(@alice), headers: headers_with_auth(@alice)
    assert_response :success

    top = response.parsed_body["top_skills"]
    assert_instance_of Array, top
    assert top.any? { |s| s["name"] == "Data Analysis" }
  end

  test "GET /api/v1/authors/:id/analytics top_skills includes revenue and rating" do
    get analytics_api_v1_author_url(@alice), headers: headers_with_auth(@alice)
    assert_response :success

    top = response.parsed_body["top_skills"]
    assert top[0].key?("execution_count")
    assert top[0].key?("total_revenue")
  end

  test "GET /api/v1/authors/:id/analytics includes recent_executions" do
    get analytics_api_v1_author_url(@alice), headers: headers_with_auth(@alice)
    assert_response :success

    recent = response.parsed_body["recent_executions"]
    assert_instance_of Array, recent
    assert recent.any? { |e| e["skill_name"] == "Data Analysis" }
  end

  test "GET /api/v1/authors/:id/analytics recent_executions has correct keys" do
    get analytics_api_v1_author_url(@alice), headers: headers_with_auth(@alice)
    assert_response :success

    recent = response.parsed_body["recent_executions"].first
    assert recent.key?("skill_name")
    assert recent.key?("buyer_name")
    assert recent.key?("status")
    assert recent.key?("amount")
    assert recent.key?("timestamp")
  end

  test "GET /api/v1/authors/:id/analytics returns zeros for author with no executions" do
    get analytics_api_v1_author_url(@charlie), headers: headers_with_auth(@charlie)
    assert_response :success

    body = response.parsed_body
    assert_equal 0, body["total_skills"]
    assert_equal 0, body["total_executions"]
    assert_equal 0.0, body["total_earnings"]
    assert_equal 0.0, body["total_slashed"]
    assert_nil body["average_rating"]
  end

  test "GET /api/v1/authors/:id/analytics includes average_rating" do
    # Alice's skill (data_analysis) has a review with rating 4
    get analytics_api_v1_author_url(@alice), headers: headers_with_auth(@alice)
    assert_response :success
    assert_equal 4.0, response.parsed_body["average_rating"]
  end

  # ── Analytics Earnings ─────────────────────────────────────────

  test "GET /api/v1/authors/:id/earnings returns earnings data" do
    get earnings_api_v1_author_url(@alice), headers: headers_with_auth(@alice)
    assert_response :success

    body = response.parsed_body
    assert body.key?("earnings_over_time")
    assert body.key?("total_earnings")
    assert body.key?("average_per_day")
    assert body.key?("best_skill")
  end

  test "GET /api/v1/authors/:id/earnings returns 403 for another author" do
    get earnings_api_v1_author_url(@alice), headers: headers_with_auth(@bob)
    assert_response :forbidden
    assert_includes response.parsed_body["error"], "You can only access your own analytics"
  end

  test "GET /api/v1/authors/:id/earnings returns empty data for author with no earnings" do
    get earnings_api_v1_author_url(@charlie), headers: headers_with_auth(@charlie)
    assert_response :success

    body = response.parsed_body
    assert_equal [], body["earnings_over_time"]
    assert_equal 0.0, body["total_earnings"]
    assert_equal 0.0, body["average_per_day"]
    assert_nil body["best_skill"]
  end

  # ── Period Filtering ───────────────────────────────────────────

  test "GET /api/v1/authors/:id/analytics supports period=last_7_days" do
    get analytics_api_v1_author_url(@alice, period: "last_7_days"), headers: headers_with_auth(@alice)
    assert_response :success
  end

  test "GET /api/v1/authors/:id/analytics supports period=last_30_days" do
    get analytics_api_v1_author_url(@alice, period: "last_30_days"), headers: headers_with_auth(@alice)
    assert_response :success
  end

  test "GET /api/v1/authors/:id/analytics supports period=this_year" do
    get analytics_api_v1_author_url(@alice, period: "this_year"), headers: headers_with_auth(@alice)
    assert_response :success
  end

  test "GET /api/v1/authors/:id/analytics supports period=all" do
    get analytics_api_v1_author_url(@alice, period: "all"), headers: headers_with_auth(@alice)
    assert_response :success
  end
end
