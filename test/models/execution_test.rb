require "test_helper"

class ExecutionTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    execution = Execution.new(
      skill: skills(:data_analysis),
      buyer: accounts(:bob),
      status: "pending",
      timestamp: Time.current
    )
    assert execution.valid?
  end

  test "should require skill" do
    execution = Execution.new(buyer: accounts(:bob), status: "pending", timestamp: Time.current)
    assert_not execution.valid?
    assert_includes execution.errors[:skill], "must exist"
  end

  test "should require buyer" do
    execution = Execution.new(skill: skills(:data_analysis), status: "pending", timestamp: Time.current)
    assert_not execution.valid?
    assert_includes execution.errors[:buyer], "must exist"
  end

  test "should belong to skill" do
    execution = executions(:execution_one)
    assert_instance_of Skill, execution.skill
  end

  test "should belong to buyer" do
    execution = executions(:execution_one)
    assert_instance_of Account, execution.buyer
  end

  test "should default status to pending" do
    execution = Execution.new(
      skill: skills(:data_analysis),
      buyer: accounts(:bob),
      timestamp: Time.current
    )
    assert_equal "pending", execution.status
  end
end
