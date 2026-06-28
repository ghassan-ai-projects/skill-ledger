require "test_helper"

class AccountTest < ActiveSupport::TestCase
  def valid_attributes(overrides = {})
    { name: "NewAgent", balance: 500, status: "active" }.merge(overrides)
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

  test "defaults admin to false" do
    account = Account.create!(valid_attributes(name: "NonAdminAgent"))
    assert_equal false, account.admin?
  end

  test "admin account from fixture is an admin" do
    assert accounts(:admin_user).admin?
    assert_not accounts(:alice).admin?
  end

  test "should allow zero balance" do
    account = Account.new(valid_attributes(balance: 0))
    assert account.valid?
  end

  test "should only allow supported statuses" do
    account = Account.new(valid_attributes(status: "archived"))
    assert_not account.valid?
    assert_includes account.errors[:status], "is not included in the list"

    %w[active suspended disabled].each do |status|
      assert Account.new(valid_attributes(name: "Agent-#{status}", status: status)).valid?
    end
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

  test "should have purchases" do
    account = accounts(:bob)
    assert_respond_to account, :purchases
  end

  test "should have sent ledger entries" do
    account = accounts(:alice)
    assert_respond_to account, :sent_ledger_entries
  end

  test "should have received ledger entries" do
    account = accounts(:bob)
    assert_respond_to account, :received_ledger_entries
  end

  test "should generate api_key_digest on create" do
    account = Account.create!(name: "KeyTest", balance: 100, status: "active")
    assert_not_nil account.api_key
    assert_not_nil account.api_key_digest
    assert BCrypt::Password.new(account.api_key_digest) == account.api_key
  end

  test "api_key plaintext is not persisted after reload" do
    account = Account.create!(name: "ReloadKey", balance: 100, status: "active")
    assert_not_nil account.api_key

    reloaded = account.reload
    assert_nil reloaded.api_key
    assert_not_nil reloaded.api_key_digest
  end

  test "authenticate_api_key returns the matching account" do
    assert_equal accounts(:alice), Account.authenticate_api_key("test_alice_api_key_123")
    assert_nil Account.authenticate_api_key("not_a_real_key")
  end
end
