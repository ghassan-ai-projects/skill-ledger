class SkillReview < ApplicationRecord
  STATUSES = %w[pending approved rejected revoked].freeze
  REVIEW_TYPES = %w[automated manual appeal revocation].freeze

  belongs_to :skill_version
  belongs_to :reviewer_account, class_name: "Account", optional: true

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :review_type, presence: true, inclusion: { in: REVIEW_TYPES }

  def approved?
    status == "approved"
  end

  def revoked?
    status == "revoked"
  end
end
