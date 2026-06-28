require "test_helper"

class SkillReviewTest < ActiveSupport::TestCase
  test "fixture review is valid" do
    assert skill_reviews(:data_analysis_v1_review).valid?
  end

  test "requires known status" do
    review = SkillReview.new(
      skill_version: skill_versions(:data_analysis_v1),
      status: "invalid",
      review_type: "automated"
    )

    assert_not review.valid?
    assert_includes review.errors[:status], "is not included in the list"
  end

  test "requires known review_type" do
    review = SkillReview.new(
      skill_version: skill_versions(:data_analysis_v1),
      status: "pending",
      review_type: "invalid"
    )

    assert_not review.valid?
    assert_includes review.errors[:review_type], "is not included in the list"
  end

  test "approved? and revoked? reflect status" do
    review = skill_reviews(:data_analysis_v1_review)
    assert review.approved?
    assert_not review.revoked?

    review.status = "revoked"
    assert review.revoked?
    assert_not review.approved?
  end
end
