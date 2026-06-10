require "test_helper"

class SkillVerificationTest < ActiveSupport::TestCase
  test "fixture verification is valid" do
    assert skill_verifications(:data_analysis_v1_verification).valid?
  end

  test "requires known status" do
    verification = SkillVerification.new(
      skill_version: skill_versions(:data_analysis_v1),
      status: "invalid",
      checks: { artifact_type_supported: true }
    )

    assert_not verification.valid?
    assert_includes verification.errors[:status], "is not included in the list"
  end

  test "requires checks" do
    verification = SkillVerification.new(
      skill_version: skill_versions(:data_analysis_v1),
      status: "pending",
      checks: nil
    )

    assert_not verification.valid?
    assert_includes verification.errors[:checks], "can't be blank"
  end
end
