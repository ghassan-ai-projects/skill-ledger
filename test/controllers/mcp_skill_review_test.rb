require "test_helper"

class McpSkillReviewTest < ActionDispatch::IntegrationTest
  setup do
    @alice = accounts(:alice)
    @admin = accounts(:admin_user)
    @skill = Skill.create!(name: "MCP Review Skill", author: @alice, price: 10, listing_status: "draft")
    @version = SkillVersion.create!(skill: @skill, version: "1.0.0", status: "verified")
    @review = SkillReview.create!(skill_version: @version, status: "pending", review_type: "automated", submitted_at: Time.current)
  end

  def rpc(method:, params: {}, account:, id: "test-id")
    post "/api/v1/mcp",
         params: { jsonrpc: "2.0", id: id, method: method, params: params },
         headers: headers_with_auth(account), as: :json
  end

  test "author can fetch review status for their own version" do
    rpc(method: "skills/version.review_status", params: { skill_id: @skill.id, version: "1.0.0" }, account: @alice)

    assert_response :success
    review = response.parsed_body.dig("result", "review")
    assert_equal "pending", review["status"]
    assert_equal "automated", review["review_type"]
  end

  test "admin can list pending reviews" do
    rpc(method: "skills/review.list_pending", account: @admin)

    assert_response :success
    ids = response.parsed_body.dig("result", "skill_reviews").map { |r| r["id"] }
    assert_includes ids, @review.id
  end

  test "non-admin cannot list pending reviews" do
    rpc(method: "skills/review.list_pending", account: @alice)

    assert_response :unprocessable_entity
    error = response.parsed_body["error"]
    assert_not_nil error
    assert_match(/Admin access required/, error["message"])
  end

  test "admin can decide a review" do
    rpc(method: "skills/review.decide", params: { review_id: @review.id, decision: "approve", reason: "ok" }, account: @admin)

    assert_response :success
    result = response.parsed_body.dig("result", "skill_review")
    assert_equal "approved", result["status"]
    assert_equal "ok", result["decision_reason"]
  end

  test "non-admin cannot decide a review" do
    rpc(method: "skills/review.decide", params: { review_id: @review.id, decision: "approve" }, account: @alice)

    assert_response :unprocessable_entity
    error = response.parsed_body["error"]
    assert_not_nil error
    assert_match(/Admin access required/, error["message"])
    assert_equal "pending", @review.reload.status
  end
end
