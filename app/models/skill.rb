class Skill < ApplicationRecord
  LISTING_STATUSES = %w[draft listed suspended].freeze

  belongs_to :author, class_name: "Account"
  has_many :executions, dependent: :destroy
  has_many :reviews, through: :executions
  has_many :favorites, dependent: :destroy
  has_many :skill_versions, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :listing_status, presence: true, inclusion: { in: LISTING_STATUSES }
  validates :stake_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :price_per_call, numericality: { greater_than_or_equal_to: 0 }
  validates :webhook_url, format: { with: /\Ahttps:\/\/.+\z/ }, allow_nil: true

  before_validation :ensure_slug, on: :create

  def average_rating
    reviews.average(:rating)&.to_f
  end

  def review_count
    reviews.count
  end

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
