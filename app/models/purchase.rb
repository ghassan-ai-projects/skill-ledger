class Purchase < ApplicationRecord
  STATUSES = %w[paid refunded revoked].freeze

  belongs_to :buyer, class_name: "Account"
  belongs_to :skill_version

  validates :amount, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :entitlement_token, presence: true, uniqueness: true

  before_validation :ensure_entitlement_token, on: :create

  def paid?
    status == "paid"
  end

  private

  def ensure_entitlement_token
    self.entitlement_token ||= SecureRandom.hex(24)
  end
end
