require "bcrypt"

class Account < ApplicationRecord
  attribute :status, :string, default: "active"

  has_many :authored_skills, class_name: "Skill", foreign_key: :author_id, dependent: :destroy
  has_many :purchases, foreign_key: :buyer_id, dependent: :destroy
  has_many :sent_ledger_entries, class_name: "LedgerEntry", foreign_key: :from_account_id, dependent: :destroy
  has_many :received_ledger_entries, class_name: "LedgerEntry", foreign_key: :to_account_id, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorited_skills, through: :favorites, source: :skill

  validates :name, presence: true, uniqueness: true
  validates :balance, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: %w[active suspended disabled] }

  before_create :generate_api_key

  def self.authenticate_api_key(plaintext)
    return if plaintext.blank?

    # BCrypt uses a random salt, so lookup is O(n) for now.
    find_each do |account|
      next if account.api_key_digest.blank?

      return account if BCrypt::Password.new(account.api_key_digest) == plaintext
    rescue BCrypt::Errors::InvalidHash
      next
    end

    nil
  end

  def api_key
    @plaintext_api_key
  end

  private

  def generate_api_key
    return if api_key_digest.present?

    @plaintext_api_key = SecureRandom.hex(32)
    self.api_key_digest = BCrypt::Password.create(@plaintext_api_key)
  end
end
