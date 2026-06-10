class SkillPurchaseService
  class Error < StandardError; end

  def initialize(buyer:)
    @buyer = buyer
  end

  def call(skill_id:, version:)
    skill = Skill.find(skill_id)
    skill_version = skill.skill_versions.find_by!(version: version)

    validate_purchaseable!(skill, skill_version)

    Purchase.transaction do
      existing_purchase = Purchase.lock.find_by(
        buyer: @buyer,
        skill_version: skill_version,
        status: "paid"
      )
      return existing_purchase if existing_purchase

      author = skill.author
      amount = skill.price_per_call

      raise Error, "Buyer has insufficient balance" if @buyer.reload.balance < amount

      @buyer.update!(balance: @buyer.balance - amount)
      author.update!(balance: author.balance + amount)

      LedgerEntry.create!(
        from_account: @buyer,
        to_account: author,
        amount: amount,
        entry_type: "skill_purchase",
        timestamp: Time.current
      )

      Purchase.create!(
        buyer: @buyer,
        skill_version: skill_version,
        amount: amount,
        status: "paid"
      )
    end
  rescue ActiveRecord::RecordInvalid => e
    raise Error, e.message
  end

  private

  def validate_purchaseable!(skill, skill_version)
    raise Error, "Cannot purchase your own skill" if skill.author_id == @buyer.id
    raise Error, "Skill is not publicly listed" unless skill.listing_status == "listed"
    raise Error, "Skill version is not verified" unless skill_version.status == "verified"

    verification = skill_version.skill_verification
    raise Error, "Skill version is not verified" unless verification&.status == "verified"
  end
end
