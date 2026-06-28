require "test_helper"

class SkillPolicyCheckServiceTest < ActiveSupport::TestCase
  setup do
    @skill = Skill.create!(name: "Policy Check Skill", author: accounts(:alice), price: 10, listing_status: "draft")
    @version = SkillVersion.create!(skill: @skill, version: "1.0.0", status: "draft")
  end

  def manifest_with(overrides = {})
    {
      "name" => @skill.slug,
      "description" => "A real description of what this skill does",
      "version" => "1.0.0",
      "runtime" => "client",
      "entrypoint" => "policy_check.execute",
      "input_schema" => { "type" => "object" },
      "output_schema" => { "type" => "object" },
      "permissions" => { "network_access" => "none" }
    }.merge(overrides)
  end

  def build_artifact(manifest)
    SkillArtifact.create!(
      skill_version: @version,
      artifact_type: "mcp_tool_manifest",
      manifest: manifest,
      checksum: SkillArtifactVerificationService.checksum_for_manifest(manifest)
    )
  end

  test "passes a clean manifest with no files" do
    build_artifact(manifest_with)

    result = SkillPolicyCheckService.new(skill_version: @version).call

    assert result[:passed]
    assert_not result[:hard_failed]
    assert result[:checks].values.all?
  end

  test "hard fails on path traversal" do
    build_artifact(manifest_with("files" => [
      { "path" => "../../etc/passwd", "media_type" => "text/plain", "content" => "x" }
    ]))

    result = SkillPolicyCheckService.new(skill_version: @version).call

    assert_not result[:passed]
    assert result[:hard_failed]
    assert_not result[:checks][:no_path_traversal]
    assert_not result[:checks][:bundled_file_paths_allowed]
  end

  test "hard fails on absolute file paths" do
    build_artifact(manifest_with("files" => [
      { "path" => "/etc/passwd", "media_type" => "text/plain", "content" => "x" }
    ]))

    result = SkillPolicyCheckService.new(skill_version: @version).call

    assert_not result[:passed]
    assert result[:hard_failed]
  end

  test "hard fails on obvious secrets in bundled file content" do
    build_artifact(manifest_with("files" => [
      { "path" => "config.txt", "media_type" => "text/plain", "content" => "key=AKIAABCDEFGHIJKLMNOP" }
    ]))

    result = SkillPolicyCheckService.new(skill_version: @version).call

    assert_not result[:passed]
    assert result[:hard_failed]
    assert_not result[:checks][:no_obvious_secrets]
  end

  test "soft fails on missing permissions without being a hard failure" do
    build_artifact(manifest_with.except("permissions"))

    result = SkillPolicyCheckService.new(skill_version: @version).call

    assert_not result[:passed]
    assert_not result[:hard_failed]
    assert_not result[:checks][:permissions_declared_explicitly]
  end

  test "soft fails on generic description" do
    build_artifact(manifest_with("description" => "test"))

    result = SkillPolicyCheckService.new(skill_version: @version).call

    assert_not result[:passed]
    assert_not result[:hard_failed]
    assert_not result[:checks][:description_and_name_consistent]
  end
end
