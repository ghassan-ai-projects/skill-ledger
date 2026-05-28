require "test_helper"

class LedgerEntryTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    entry = LedgerEntry.new(
      from_account: accounts(:alice),
      to_account: accounts(:bob),
      amount: 50,
      entry_type: "transfer",
      timestamp: Time.current
    )
    assert entry.valid?
  end

  test "should require from_account" do
    entry = LedgerEntry.new(to_account: accounts(:bob), amount: 50, entry_type: "transfer", timestamp: Time.current)
    assert_not entry.valid?
    assert_includes entry.errors[:from_account], "must exist"
  end

  test "should require to_account" do
    entry = LedgerEntry.new(from_account: accounts(:alice), amount: 50, entry_type: "transfer", timestamp: Time.current)
    assert_not entry.valid?
    assert_includes entry.errors[:to_account], "must exist"
  end

  test "should require positive amount" do
    entry = LedgerEntry.new(
      from_account: accounts(:alice),
      to_account: accounts(:bob),
      amount: 0,
      entry_type: "transfer",
      timestamp: Time.current
    )
    assert_not entry.valid?
    assert_includes entry.errors[:amount], "must be greater than 0"
  end

  test "should require entry_type" do
    entry = LedgerEntry.new(
      from_account: accounts(:alice),
      to_account: accounts(:bob),
      amount: 50,
      timestamp: Time.current
    )
    assert_not entry.valid?
    assert_includes entry.errors[:entry_type], "can't be blank"
  end

  test "should belong to from_account" do
    entry = ledger_entries(:transfer_one)
    assert_instance_of Account, entry.from_account
  end

  test "should belong to to_account" do
    entry = ledger_entries(:transfer_one)
    assert_instance_of Account, entry.to_account
  end
end
