class Account < ApplicationRecord
  has_many :authored_skills, class_name: "Skill", foreign_key: :author_id, dependent: :destroy
  has_many :purchased_executions, class_name: "Execution", foreign_key: :buyer_id, dependent: :destroy
  has_many :sent_ledger_entries, class_name: "LedgerEntry", foreign_key: :from_account_id, dependent: :destroy
  has_many :received_ledger_entries, class_name: "LedgerEntry", foreign_key: :to_account_id, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :balance, numericality: { greater_than_or_equal_to: 0 }
end
