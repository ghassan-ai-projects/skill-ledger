class Account < ApplicationRecord
  has_many :authored_skills, class_name: "Skill", foreign_key: :author_id, dependent: :destroy
  has_many :purchases, foreign_key: :buyer_id, dependent: :destroy
  has_many :sent_ledger_entries, class_name: "LedgerEntry", foreign_key: :from_account_id, dependent: :destroy
  has_many :received_ledger_entries, class_name: "LedgerEntry", foreign_key: :to_account_id, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorited_skills, through: :favorites, source: :skill

  validates :name, presence: true, uniqueness: true
  validates :balance, numericality: { greater_than_or_equal_to: 0 }
  validates :api_key, presence: true, uniqueness: true

  before_validation :generate_api_key, on: :create

  private

  def generate_api_key
    self.api_key ||= SecureRandom.hex(32)
  end
end
