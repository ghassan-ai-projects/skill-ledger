class Execution < ApplicationRecord
  belongs_to :skill
  belongs_to :buyer, class_name: "Account"
  has_one :review, dependent: :destroy

  validates :status, presence: true
  validates :timestamp, presence: true
end
