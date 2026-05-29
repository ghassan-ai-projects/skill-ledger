require "test_helper"

class AccountTest < ActiveSupport::TestCase
  def valid_attributes(overrides = {})
    { name: "NewAgent", balance: 500 }.merge(overrides)
  end

  test "should be valid with valid attributes" do
    account = Account.new(valid_attributes)
    assert account.valid?
  end

  test "should require name" do
    account = Account.new(valid_attributes(name: nil))
    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
  end

  test "should require unique name" do
    account = Account.new(valid_attributes(name: accounts(:alice).name))
    assert_not account.valid?
    assert_includes account.errors[:name], "has already been taken"
  end

  test "should require non-negative balance" do
    account = Account.new(valid_attributes(balance: -1))
    assert_not account.valid?
    assert_includes account.errors[:balance], "must be greater than or equal to 0"
  end

  test "should allow zero balance" do
    account = Account.new(valid_attributes(balance: 0))
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

  test "should generate api_key on create" do
    account = Account.create!(name: "KeyTest", balance: 100)
    assert_not_nil account.api_key
    assert_equal 64, account.api_key.length
  end

  test "api_key is auto-generated on validation" do
    account = Account.new(name: "AutoKey", balance: 100)
    account.valid?
    assert_not_nil account.api_key
    assert_equal 64, account.api_key.length
  end

  test "api_key must be unique" do
    account = Account.new(name: "DupKey", balance: 100, api_key: accounts(:alice).api_key)
    assert_not account.valid?
    assert_includes account.errors[:api_key], "has already been taken"
  end
end
