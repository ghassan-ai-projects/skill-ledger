require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    account = Account.new(name: "NewAgent", balance: 500)
    assert account.valid?
  end

  test "should require name" do
    account = Account.new(balance: 100)
    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
  end

  test "should require unique name" do
    account = Account.new(name: accounts(:alice).name, balance: 100)
    assert_not account.valid?
    assert_includes account.errors[:name], "has already been taken"
  end

  test "should require non-negative balance" do
    account = Account.new(name: "NewAgent", balance: -1)
    assert_not account.valid?
    assert_includes account.errors[:balance], "must be greater than or equal to 0"
  end

  test "should allow zero balance" do
    account = Account.new(name: "NewAgent", balance: 0)
    assert account.valid?
  end

  test "balance must never go negative on update" do
    account = accounts(:charlie) # balance is 250
    account.balance = -1
    assert_not account.valid?
    assert_includes account.errors[:balance], "must be greater than or equal to 0"
  end

  test "should have authored skills" do
    account = accounts(:alice)
    assert_respond_to account, :authored_skills
    assert account.authored_skills.any?
  end

  test "should have purchased executions" do
    account = accounts(:bob)
    assert_respond_to account, :purchased_executions
  end

  test "should have sent ledger entries" do
    account = accounts(:alice)
    assert_respond_to account, :sent_ledger_entries
  end

  test "should have received ledger entries" do
    account = accounts(:bob)
    assert_respond_to account, :received_ledger_entries
  end
end
