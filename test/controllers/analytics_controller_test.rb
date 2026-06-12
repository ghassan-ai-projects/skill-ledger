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
    assert_equal 1, body["total_skills"]
    assert_equal 1, body["listed_skills"]
    assert_equal 1, body["verified_versions"]
    assert_equal 1, body["total_purchases"]
    assert_equal 50.0, body["total_revenue"]
    assert body.key?("top_skills")
    assert body.key?("recent_purchases")
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

  test "GET /api/v1/authors/:id/analytics includes top_skills" do
    get analytics_api_v1_author_url(@alice), headers: headers_with_auth(@alice)
    assert_response :success

    top = response.parsed_body["top_skills"]
    assert_instance_of Array, top
    assert top.any? { |s| s["name"] == "Data Analysis" }
  end

  test "GET /api/v1/authors/:id/analytics top_skills includes purchase stats" do
    get analytics_api_v1_author_url(@alice), headers: headers_with_auth(@alice)
    assert_response :success

    top = response.parsed_body["top_skills"]
    assert top[0].key?("purchase_count")
    assert top[0].key?("total_revenue")
  end

  test "GET /api/v1/authors/:id/analytics includes recent_purchases" do
    get analytics_api_v1_author_url(@alice), headers: headers_with_auth(@alice)
    assert_response :success

    recent = response.parsed_body["recent_purchases"]
    assert_instance_of Array, recent
    assert recent.any? { |e| e["skill_name"] == "Data Analysis" }
  end

  test "GET /api/v1/authors/:id/analytics recent_purchases has correct keys" do
    get analytics_api_v1_author_url(@alice), headers: headers_with_auth(@alice)
    assert_response :success

    recent = response.parsed_body["recent_purchases"].first
    assert recent.key?("skill_name")
    assert recent.key?("buyer_name")
    assert recent.key?("status")
    assert recent.key?("amount")
    assert recent.key?("purchased_at")
  end

  test "GET /api/v1/authors/:id/analytics returns zeros for author with no purchases" do
    get analytics_api_v1_author_url(@charlie), headers: headers_with_auth(@charlie)
    assert_response :success

    body = response.parsed_body
    assert_equal 0, body["total_skills"]
    assert_equal 0, body["total_purchases"]
    assert_equal 0.0, body["total_revenue"]
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
    assert_equal 50.0, body["total_earnings"]
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
