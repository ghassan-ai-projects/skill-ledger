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

    LedgerTransactionService.new(
      from_account: buyer,
      to_account: skill.author,
      amount: skill.price_per_call,
      entry_type: "skill_execution"
    ).call

    execution = Execution.create!(
      skill: skill,
      buyer: buyer,
      status: "completed",
      timestamp: Time.current
    )

    ExecutionWebhookJob.perform_later(execution.id)

    execution
  rescue LedgerTransactionService::InsufficientBalanceError => e
    raise Error, e.message
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def fail(execution_id:)
    execution = Execution.find(execution_id)
    raise Error, "Execution is already failed" if execution.status == "failed"

    skill = execution.skill
    author = skill.author
    buyer = execution.buyer

    Account.transaction do
      author.update!(balance: author.balance - skill.stake_amount)
      buyer.update!(balance: buyer.balance + skill.price_per_call)
      buyer.update!(balance: buyer.balance + skill.stake_amount)
      author.update!(balance: author.balance - skill.price_per_call)

      LedgerEntry.create!(
        from_account: author,
        to_account: buyer,
        amount: skill.stake_amount,
        entry_type: "slash",
        timestamp: Time.current
      )

      LedgerEntry.create!(
        from_account: author,
        to_account: buyer,
        amount: skill.price_per_call,
        entry_type: "refund",
        timestamp: Time.current
      )

      execution.update!(status: "failed")
    end

    ExecutionWebhookJob.perform_later(execution.id)

    execution
  end
  # rubocop:enable Metrics/MethodLength
end
