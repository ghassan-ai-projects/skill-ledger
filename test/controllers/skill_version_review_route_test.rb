require "test_helper"

class SkillVersionReviewRouteTest < ActionDispatch::IntegrationTest
  setup do
    @alice = accounts(:alice)
    @skill = Skill.create!(name: "Version Review Route Skill", author: @alice, price: 10, listing_status: "draft")
    @version = SkillVersion.create!(skill: @skill, version: "1.0.0", status: "verified")
    @review = SkillReview.create!(skill_version: @version, status: "pending", review_type: "automated", submitted_at: Time.current)
  end

  test "author can view review status for their own version" do
    get "/api/v1/skills/#{@skill.id}/versions/#{@version.id}/review", headers: headers_with_auth(@alice)

    assert_response :success
    body = response.parsed_body
    assert_equal @skill.id, body["skill_id"]
    assert_equal "1.0.0", body["version"]
    assert_equal "pending", body["status"]
    assert_equal "automated", body["review_type"]
  end

  test "returns nil fields when no review exists yet" do
    draft_version = SkillVersion.create!(skill: @skill, version: "2.0.0", status: "draft")

    get "/api/v1/skills/#{@skill.id}/versions/#{draft_version.id}/review", headers: headers_with_auth(@alice)

    assert_response :success
    assert_nil response.parsed_body["status"]
  end
end
