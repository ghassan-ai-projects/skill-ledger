require "test_helper"

class SkillTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    skill = Skill.new(
      name: "Test Skill",
      author: accounts(:alice),
      price: 50
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

  test "should require non-negative price" do
    skill = Skill.new(name: "Test Skill", author: accounts(:alice), price: -1)
    assert_not skill.valid?
    assert_includes skill.errors[:price], "must be greater than or equal to 0"
  end

  test "should allow zero price" do
    skill = Skill.new(name: "Free Skill", author: accounts(:alice), price: 0)
    assert skill.valid?
  end

  test "should belong to author" do
    skill = skills(:data_analysis)
    assert_instance_of Account, skill.author
  end

  test "should auto-generate slug from name" do
    skill = Skill.new(
      name: "Deterministic Pricing Review",
      author: accounts(:alice),
      price: 5
    )

    skill.valid?
    assert_equal "deterministic-pricing-review", skill.slug
  end

  test "should require unique slug" do
    skill = Skill.new(
      name: "Another Data Analysis",
      slug: skills(:data_analysis).slug,
      author: accounts(:alice),
      price: 5
    )

    assert_not skill.valid?
    assert_includes skill.errors[:slug], "has already been taken"
  end

  test "should require known listing status" do
    skill = Skill.new(
      name: "Bad Listing Status",
      author: accounts(:alice),
      price: 5,
      listing_status: "other"
    )

    assert_not skill.valid?
    assert_includes skill.errors[:listing_status], "is not included in the list"
  end

end
