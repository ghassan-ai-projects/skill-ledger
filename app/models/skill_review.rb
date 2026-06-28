class SkillReview < ApplicationRecord
  STATUSES = %w[pending approved rejected revoked].freeze
  REVIEW_TYPES = %w[automated manual appeal revocation].freeze

  belongs_to :skill_version
  belongs_to :reviewer_account, class_name: "Account", optional: true
  has_many :skill_review_events, -> { order(:created_at, :id) }, dependent: :destroy

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :review_type, presence: true, inclusion: { in: REVIEW_TYPES }

  # Append-only history entry. Records the transition into the current status
  # so the full decision trail survives later approvals, revocations, etc.
  def record_event!(event_type:, to_status:, from_status: nil, actor_account: nil, reason: nil)
    skill_review_events.create!(
      event_type: event_type,
      from_status: from_status,
      to_status: to_status,
      actor_account: actor_account,
      reason: reason
    )
  end

  def approved?
    status == "approved"
  end

  def revoked?
    status == "revoked"
  end
end
