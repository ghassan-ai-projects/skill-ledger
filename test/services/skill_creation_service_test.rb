require "test_helper"

class SkillCreationServiceTest < ActiveSupport::TestCase
  setup do
    @alice = accounts(:alice)
    @bob = accounts(:bob)
    @valid_params = {
      name: "New Test Skill",
      description: "A test skill",
      author_id: @alice.id,
      price_per_call: 10.00,
      stake_amount: 50.00
    }
  end

  test "creates a skill successfully" do
    assert_difference("Skill.count", 1) do
      result = SkillCreationService.new(@valid_params).call
      assert_equal "New Test Skill", result["name"]
      assert_equal @alice.id, result["author_id"]
    end
  end

  test "returns error when author not found" do
    assert_raises SkillCreationService::Error, match: "Author not found" do
      SkillCreationService.new(@valid_params.merge(author_id: 99999)).call
    end
  end

  test "returns error when author has insufficient balance for stake" do
    assert_raises SkillCreationService::Error, match: "insufficient balance" do
      SkillCreationService.new(@valid_params.merge(stake_amount: 9999.00, author_id: @bob.id)).call
    end
  end

  test "returns error when name is missing" do
    assert_raises SkillCreationService::Error do
      SkillCreationService.new(@valid_params.except(:name)).call
    end
  end

  test "rejects negative price" do
    assert_raises SkillCreationService::Error do
      SkillCreationService.new(@valid_params.merge(price_per_call: -10.00)).call
    end
  end
end
