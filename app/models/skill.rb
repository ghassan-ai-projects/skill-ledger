class Skill < ApplicationRecord
  LISTING_STATUSES = %w[draft listed suspended].freeze

  belongs_to :author, class_name: "Account"
  has_many :favorites, dependent: :destroy
  has_many :skill_versions, dependent: :destroy
  has_many :purchases, through: :skill_versions

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :listing_status, presence: true, inclusion: { in: LISTING_STATUSES }
  validates :price, numericality: { greater_than_or_equal_to: 0 }

  before_validation :ensure_slug, on: :create

  def favorite_count
    favorites.count
  end

  def is_favorited(account)
    return false unless account
    favorites.exists?(account_id: account.id)
  end

  private

  def ensure_slug
    self.slug ||= name.to_s.parameterize if name.present?
  end
end
