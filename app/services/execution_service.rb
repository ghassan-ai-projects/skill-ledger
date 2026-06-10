class ExecutionService
  class Error < StandardError; end

  def initialize(params = {})
    @params = params
  end

  # rubocop:disable Metrics/MethodLength
  def create(skill_id:, buyer_id:)
    skill = Skill.find(skill_id)
    buyer = Account.find_by(id: buyer_id)

    raise Error, "Buyer not found" unless buyer
    raise Error, "Cannot execute your own skill" if buyer == skill.author
    raise Error, "Buyer has insufficient balance" if buyer.balance < skill.price_per_call

    execution = nil
    Account.transaction do
      buyer.update!(
        balance: buyer.balance - skill.price_per_call,
        escrow_balance: buyer.escrow_balance + skill.price_per_call
      )

      execution = Execution.create!(
        skill: skill,
        buyer: buyer,
        status: "pending",
        timestamp: Time.current
      )
    end

    ExecutionWebhookJob.perform_later(execution.id)

    execution
  rescue ActiveRecord::RecordInvalid => e
    raise Error, e.message
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def complete(execution_id:)
    execution = Execution.find(execution_id)
    raise Error, "Execution is not pending" unless execution.status == "pending"

    skill = execution.skill
    author = skill.author
    buyer = execution.buyer

    Account.transaction do
      raise Error, "Escrow balance is insufficient" if buyer.escrow_balance < skill.price_per_call

      buyer.update!(escrow_balance: buyer.escrow_balance - skill.price_per_call)
      author.update!(balance: author.balance + skill.price_per_call)

      LedgerEntry.create!(
        from_account: buyer,
        to_account: author,
        amount: skill.price_per_call,
        entry_type: "skill_execution",
        timestamp: Time.current
      )

      execution.update!(status: "completed")
    end

    execution
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def fail(execution_id:)
    execution = Execution.find(execution_id)
    raise Error, "Execution is already failed" if execution.status == "failed"
    raise Error, "Execution is not pending" unless execution.status == "pending"

    skill = execution.skill
    author = skill.author
    buyer = execution.buyer

    Account.transaction do
      raise Error, "Escrow balance is insufficient" if buyer.escrow_balance < skill.price_per_call
      raise Error, "Author locked stake is insufficient" if author.locked_stake < skill.stake_amount

      # Refund buyer's escrow
      buyer.update!(
        escrow_balance: buyer.escrow_balance - skill.price_per_call,
        balance: buyer.balance + skill.price_per_call
      )

      # Slash author's locked stake
      author.update!(locked_stake: author.locked_stake - skill.stake_amount)
      buyer.update!(balance: buyer.balance + skill.stake_amount)

      LedgerEntry.create!(
        from_account: author,
        to_account: buyer,
        amount: skill.stake_amount,
        entry_type: "slash",
        timestamp: Time.current
      )

      execution.update!(status: "failed")
    end

    ExecutionWebhookJob.perform_later(execution.id)

    execution
  rescue ActiveRecord::RecordInvalid => e
    raise Error, e.message
  end
  # rubocop:enable Metrics/MethodLength
end
