require "test_helper"

class SkillApprovalServiceTest < ActiveSupport::TestCase
  setup do
    @skill = Skill.create!(name: "Approval Service Skill", author: accounts(:alice), price: 10, listing_status: "draft")
    @version = SkillVersion.create!(skill: @skill, version: "1.0.0", status: "verified")
    @review = SkillReview.create!(skill_version: @version, status: "pending", review_type: "automated", submitted_at: Time.current)
  end

  test "admin can approve a pending review" do
    service = SkillApprovalService.new(skill_review: @review, reviewer_account: admin_account)

    result = service.call(decision: "approve", reason: "Looks good")

    assert_equal "approved", result.status
    assert_equal "manual", result.review_type
    assert_equal admin_account, result.reviewer_account
    assert_equal "Looks good", result.decision_reason
    assert_not_nil result.decided_at
  end

  test "admin can reject a pending review" do
    service = SkillApprovalService.new(skill_review: @review, reviewer_account: admin_account)

    result = service.call(decision: "reject", reason: "Policy violation")

    assert_equal "rejected", result.status
    assert_equal "Policy violation", result.decision_reason
  end

  test "admin can revoke a previously approved review" do
    @review.update!(status: "approved")
    service = SkillApprovalService.new(skill_review: @review, reviewer_account: admin_account)

    result = service.call(decision: "revoke", reason: "Security issue found")

    assert_equal "revoked", result.status
  end

  test "records an append-only event for each decision" do
    SkillApprovalService.new(skill_review: @review, reviewer_account: admin_account).call(decision: "approve")
    SkillApprovalService.new(skill_review: @review, reviewer_account: admin_account).call(decision: "revoke", reason: "leak")

    events = @review.skill_review_events.reload
    assert_equal %w[approved revoked], events.map(&:event_type)

    revoke_event = events.last
    assert_equal "approved", revoke_event.from_status
    assert_equal "revoked", revoke_event.to_status
    assert_equal admin_account, revoke_event.actor_account
    assert_equal "leak", revoke_event.reason
  end

  test "non-admin cannot decide a review" do
    service = SkillApprovalService.new(skill_review: @review, reviewer_account: accounts(:alice))

    assert_raises SkillApprovalService::AuthorizationError do
      service.call(decision: "approve")
    end
  end

  test "raises on an unknown decision" do
    service = SkillApprovalService.new(skill_review: @review, reviewer_account: admin_account)

    assert_raises SkillApprovalService::Error do
      service.call(decision: "bogus")
    end
  end
end
