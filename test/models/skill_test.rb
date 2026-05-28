require "test_helper"

class SkillTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    skill = Skill.new(
      name: "Test Skill",
      author: accounts(:alice),
      stake_amount: 100,
      price_per_call: 50
    )
    assert skill.valid?
  end

  test "should require name" do
    skill = Skill.new(author: accounts(:alice))
    assert_not skill.valid?
    assert_includes skill.errors[:name], "can't be blank"
  end

  test "should require author" do
    skill = Skill.new(name: "Test Skill")
    assert_not skill.valid?
    assert_includes skill.errors[:author], "must exist"
  end

  test "should require non-negative stake_amount" do
    skill = Skill.new(name: "Test Skill", author: accounts(:alice), stake_amount: -1, price_per_call: 10)
    assert_not skill.valid?
    assert_includes skill.errors[:stake_amount], "must be greater than or equal to 0"
  end

  test "should require non-negative price_per_call" do
    skill = Skill.new(name: "Test Skill", author: accounts(:alice), stake_amount: 10, price_per_call: -1)
    assert_not skill.valid?
    assert_includes skill.errors[:price_per_call], "must be greater than or equal to 0"
  end

  test "should allow zero stake and price" do
    skill = Skill.new(name: "Free Skill", author: accounts(:alice), stake_amount: 0, price_per_call: 0)
    assert skill.valid?
  end

  test "should belong to author" do
    skill = skills(:data_analysis)
    assert_instance_of Account, skill.author
  end

  test "should have executions" do
    skill = skills(:data_analysis)
    assert_respond_to skill, :executions
  end
end
