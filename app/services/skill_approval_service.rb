class SkillApprovalService
  class Error < StandardError; end
  class AuthorizationError < Error; end

  DECISIONS = %w[approve reject revoke].freeze
  DECISION_TO_STATUS = {
    "approve" => "approved",
    "reject" => "rejected",
    "revoke" => "revoked"
  }.freeze

  def initialize(skill_review:, reviewer_account:)
    @skill_review = skill_review
    @reviewer_account = reviewer_account
  end

  def call(decision:, reason: nil)
    raise AuthorizationError, "Only an admin account can decide skill reviews" unless @reviewer_account&.admin?
    raise Error, "Unknown decision '#{decision}'" unless DECISIONS.include?(decision)

    @skill_review.update!(
      status: DECISION_TO_STATUS.fetch(decision),
      review_type: "manual",
      reviewer_account: @reviewer_account,
      decision_reason: reason,
      decided_at: Time.current
    )

    @skill_review
  rescue ActiveRecord::RecordInvalid => e
    raise Error, e.record.errors.full_messages.to_sentence
  end
end
