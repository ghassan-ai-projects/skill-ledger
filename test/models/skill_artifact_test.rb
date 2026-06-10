require "test_helper"

class SkillArtifactTest < ActiveSupport::TestCase
  test "fixture artifact is valid" do
    assert skill_artifacts(:data_analysis_v1_artifact).valid?
  end

  test "requires supported artifact type" do
    artifact = SkillArtifact.new(
      skill_version: skill_versions(:data_analysis_v1),
      artifact_type: "zip_bundle",
      manifest: { name: "bad" },
      checksum: "abc123"
    )

    assert_not artifact.valid?
    assert_includes artifact.errors[:artifact_type], "is not included in the list"
  end

  test "requires checksum" do
    artifact = SkillArtifact.new(
      skill_version: skill_versions(:data_analysis_v1),
      artifact_type: "mcp_tool_manifest",
      manifest: { name: "data-analysis" }
    )

    assert_not artifact.valid?
    assert_includes artifact.errors[:checksum], "can't be blank"
  end
end
