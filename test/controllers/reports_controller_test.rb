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
    assert_equal 2, body["listed_skills"]
    assert_equal 1, body["verified_skill_versions"]
    assert_equal 1, body["total_purchases"]
    assert_equal 50.0, body["total_revenue"]
    # Alice: 1000, Bob: 500, Charlie: 250 = 1750
    assert_equal 1750.0, body["total_ledger_balance"]
  end

  test "GET /api/v1/reports updates after a new purchase" do
    create_verified_skill_listing(
      name: "Deterministic Pricing Review",
      slug: "deterministic-pricing-review",
      author: @alice,
      price: 35,
      description: "Review a pricing payload for deterministic rule violations."
    ).then do |listing|
      SkillPurchaseService.new(buyer: @bob).call(skill_id: listing[:skill].id, version: listing[:version].version)
    end

    get api_v1_reports_url, headers: headers_with_auth(@alice)
    body = response.parsed_body
    assert_equal 2, body["total_purchases"]
    assert_equal 85.0, body["total_revenue"]
  end
end
