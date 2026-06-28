class SkillReviewSubmissionService
  def initialize(skill_version:)
    @skill_version = skill_version
  end

  def call
    review = @skill_version.skill_review || @skill_version.build_skill_review
    return review if review.persisted? && review.status != "pending"

    policy_result = SkillPolicyCheckService.new(skill_version: @skill_version).call
    hard_failed = policy_result[:hard_failed]

    if hard_failed
      review.assign_attributes(
        status: "rejected",
        review_type: "automated",
        policy_checks: policy_result[:checks],
        decision_reason: "Automated policy check failed: #{failed_check_names(policy_result[:checks]).join(', ')}",
        submitted_at: review.submitted_at || Time.current,
        decided_at: Time.current
      )
    else
      review.assign_attributes(
        status: "pending",
        review_type: "automated",
        policy_checks: policy_result[:checks],
        submitted_at: review.submitted_at || Time.current
      )
    end

    SkillReview.transaction do
      review.save!

      if hard_failed
        review.record_event!(event_type: "auto_rejected", to_status: "rejected", reason: review.decision_reason)
      else
        review.record_event!(event_type: "submitted", to_status: "pending")
      end
    end

    review
  end

  private

  def failed_check_names(checks)
    checks.filter_map { |name, passed| name.to_s unless passed }
  end
end
