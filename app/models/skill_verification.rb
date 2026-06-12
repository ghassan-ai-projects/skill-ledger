class SkillVerification < ApplicationRecord
  STATUSES = %w[pending verified rejected].freeze

  belongs_to :skill_version

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :checks, presence: true
end
