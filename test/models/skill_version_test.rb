require "test_helper"

class SkillVersionTest < ActiveSupport::TestCase
  test "fixture version is valid" do
    assert skill_versions(:data_analysis_v1).valid?
  end

  test "requires unique version per skill" do
    duplicate = SkillVersion.new(
      skill: skills(:data_analysis),
      version: skill_versions(:data_analysis_v1).version,
      status: "draft"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:version], "has already been taken"
  end

  test "requires known status" do
    version = SkillVersion.new(skill: skills(:data_analysis), version: "2.0.0", status: "unknown")

    assert_not version.valid?
    assert_includes version.errors[:status], "is not included in the list"
  end
end
