class Review < ApplicationRecord
  belongs_to :execution

  validates :rating, inclusion: { in: 1..5, message: "must be between 1 and 5" }
  validates :review_text, length: { maximum: 1000 }, allow_blank: true
  validates :execution, presence: true
end
