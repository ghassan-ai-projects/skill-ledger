class SkillVersion < ApplicationRecord
  STATUSES = %w[draft verified rejected retired].freeze

  belongs_to :skill
  has_one :skill_artifact, dependent: :destroy
  has_one :skill_verification, dependent: :destroy
  has_one :skill_review, dependent: :destroy
  has_many :purchases, dependent: :restrict_with_exception

  validates :version, presence: true, uniqueness: { scope: :skill_id }
  validates :status, presence: true, inclusion: { in: STATUSES }

  def verified?
    status == "verified"
  end
end
