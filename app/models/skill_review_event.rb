class SkillReviewEvent < ApplicationRecord
  EVENT_TYPES = %w[submitted auto_rejected approved rejected revoked].freeze

  belongs_to :skill_review
  belongs_to :actor_account, class_name: "Account", optional: true

  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }
  validates :to_status, presence: true, inclusion: { in: SkillReview::STATUSES }
end
