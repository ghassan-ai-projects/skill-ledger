class LedgerEntry < ApplicationRecord
  belongs_to :from_account, class_name: "Account"
  belongs_to :to_account, class_name: "Account"

  validates :amount, numericality: { greater_than: 0 }
  validates :entry_type, presence: true
  validates :timestamp, presence: true
end
