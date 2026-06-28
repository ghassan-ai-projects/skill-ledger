require "test_helper"

class Api::V1::Admin::SkillReviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @skill = Skill.create!(name: "Admin Review Skill", author: accounts(:alice), price: 10, listing_status: "draft")
    @version = SkillVersion.create!(skill: @skill, version: "1.0.0", status: "verified")
    @review = SkillReview.create!(skill_version: @version, status: "pending", review_type: "automated", submitted_at: Time.current)
  end

  test "admin can list pending reviews" do
    get "/api/v1/admin/skill_reviews", params: { status: "pending" }, headers: headers_with_auth(accounts(:admin_user))

    assert_response :success
    ids = response.parsed_body["skill_reviews"].map { |r| r["id"] }
    assert_includes ids, @review.id
  end

  test "non-admin cannot list reviews" do
    get "/api/v1/admin/skill_reviews", headers: headers_with_auth(accounts(:alice))

    assert_response :forbidden
  end

  test "admin can view a single review" do
    get "/api/v1/admin/skill_reviews/#{@review.id}", headers: headers_with_auth(accounts(:admin_user))

    assert_response :success
    assert_equal @review.id, response.parsed_body["id"]
  end

  test "admin can approve a pending review" do
    patch "/api/v1/admin/skill_reviews/#{@review.id}/approve",
          params: { reason: "Looks good" },
          headers: headers_with_auth(accounts(:admin_user)), as: :json

    assert_response :success
    assert_equal "approved", response.parsed_body["status"]
    assert_equal "Looks good", response.parsed_body["decision_reason"]
  end

  test "admin can reject a pending review" do
    patch "/api/v1/admin/skill_reviews/#{@review.id}/reject", headers: headers_with_auth(accounts(:admin_user))

    assert_response :success
    assert_equal "rejected", response.parsed_body["status"]
  end

  test "admin can revoke an approved review" do
    @review.update!(status: "approved")

    patch "/api/v1/admin/skill_reviews/#{@review.id}/revoke", headers: headers_with_auth(accounts(:admin_user))

    assert_response :success
    assert_equal "revoked", response.parsed_body["status"]
  end

  test "non-admin cannot decide a review" do
    patch "/api/v1/admin/skill_reviews/#{@review.id}/approve", headers: headers_with_auth(accounts(:alice))

    assert_response :forbidden
    assert_equal "pending", @review.reload.status
  end
end
