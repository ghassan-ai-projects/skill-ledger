class Skill < ApplicationRecord
  belongs_to :author, class_name: "Account"
  has_many :executions, dependent: :destroy

  validates :name, presence: true
  validates :stake_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :price_per_call, numericality: { greater_than_or_equal_to: 0 }
  validates :webhook_url, format: { with: /\Ahttps:\/\/.+\z/ }, allow_nil: true
end
