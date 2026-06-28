require "test_helper"

class SkillReviewEventTest < ActiveSupport::TestCase
  test "fixture events are valid" do
    assert skill_review_events(:data_analysis_v1_submitted).valid?
    assert skill_review_events(:data_analysis_v1_approved).valid?
  end

  test "requires a known event_type" do
    event = SkillReviewEvent.new(skill_review: skill_reviews(:data_analysis_v1_review), event_type: "bogus", to_status: "approved")

    assert_not event.valid?
    assert_includes event.errors[:event_type], "is not included in the list"
  end

  test "requires a known to_status" do
    event = SkillReviewEvent.new(skill_review: skill_reviews(:data_analysis_v1_review), event_type: "approved", to_status: "nope")

    assert_not event.valid?
    assert_includes event.errors[:to_status], "is not included in the list"
  end

  test "review exposes its events ordered chronologically" do
    review = skill_reviews(:data_analysis_v1_review)

    assert_equal %w[submitted approved], review.skill_review_events.map(&:event_type)
  end
end
