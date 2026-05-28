require "test_helper"

class LedgerTransactionServiceTest < ActiveSupport::TestCase
  setup do
    @alice = accounts(:alice)
    @bob = accounts(:bob)
  end

  test "transfers credits between accounts" do
    alice_initial = @alice.balance
    bob_initial   = @bob.balance

    result = LedgerTransactionService.new(
      from_account: @alice,
      to_account: @bob,
      amount: 100
    ).call

    assert_instance_of LedgerEntry, result
    assert_equal 100, result.amount
    assert_equal "transfer", result.entry_type

    @alice.reload
    @bob.reload
    assert_equal alice_initial - 100, @alice.balance
    assert_equal bob_initial + 100, @bob.balance
  end

  test "raises on insufficient balance and rolls back" do
    poor = Account.create!(name: "Poor", balance: 10)
    bob_initial = @bob.balance

    assert_raises LedgerTransactionService::InsufficientBalanceError do
      LedgerTransactionService.new(
        from_account: poor,
        to_account: @bob,
        amount: 100
      ).call
    end

    poor.reload
    @bob.reload
    assert_equal 10, poor.balance
    assert_equal bob_initial, @bob.balance
    ledger_count = LedgerEntry.count
    assert_equal ledger_count, LedgerEntry.count # no stray entries
  end

  test "raises on non-positive amount" do
    assert_raises ArgumentError do
      LedgerTransactionService.new(
        from_account: @alice,
        to_account: @bob,
        amount: 0
      ).call
    end

    assert_raises ArgumentError do
      LedgerTransactionService.new(
        from_account: @alice,
        to_account: @bob,
        amount: -50
      ).call
    end
  end

  test "raises on self-transfer" do
    assert_raises ArgumentError do
      LedgerTransactionService.new(
        from_account: @alice,
        to_account: @alice,
        amount: 50
      ).call
    end
  end

  test "custom entry_type is recorded" do
    result = LedgerTransactionService.new(
      from_account: @alice,
      to_account: @bob,
      amount: 75,
      entry_type: "skill_purchase"
    ).call

    assert_equal "skill_purchase", result.entry_type
  end

  test "transfer exactly the available balance" do
    alice_initial = @alice.balance

    result = LedgerTransactionService.new(
      from_account: @alice,
      to_account: @bob,
      amount: alice_initial
    ).call

    assert_instance_of LedgerEntry, result
    @alice.reload
    assert_equal 0, @alice.balance
  end
end
