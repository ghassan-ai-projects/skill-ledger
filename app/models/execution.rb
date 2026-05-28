class Execution < ApplicationRecord
  belongs_to :skill
  belongs_to :buyer, class_name: "Account"

  validates :status, presence: true
  validates :timestamp, presence: true
end
