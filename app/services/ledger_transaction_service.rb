class LedgerTransactionService
  class InsufficientBalanceError < StandardError; end

  def initialize(from_account:, to_account:, amount:, entry_type: "transfer")
    @from_account = from_account
    @to_account = to_account
    @amount = amount
    @entry_type = entry_type
  end

  def call
    validate_input!

    ApplicationRecord.transaction do
      # Reload accounts inside the transaction for fresh state.
      # SQLite serializes transactions, so this is race-safe.
      from = Account.find(@from_account.id)
      to   = Account.find(@to_account.id)

      raise InsufficientBalanceError, "Insufficient balance" if from.balance < @amount

      from.update!(balance: from.balance - @amount)
      to.update!(balance: to.balance + @amount)

      LedgerEntry.create!(
        from_account: from,
        to_account: to,
        amount: @amount,
        entry_type: @entry_type,
        timestamp: Time.current
      )
    end
  rescue ActiveRecord::RecordInvalid => e
    raise InsufficientBalanceError, e.message
  end

  private

  def validate_input!
    raise ArgumentError, "Amount must be positive" unless @amount&.positive?
    raise ArgumentError, "Cannot transfer to self" if @from_account == @to_account
  end
end
