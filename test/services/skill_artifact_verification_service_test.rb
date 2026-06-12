require "test_helper"

class SkillArtifactVerificationServiceTest < ActiveSupport::TestCase
  def create_version_with_artifact(manifest:, checksum:)
    skill = Skill.create!(
      name: "Verification Skill #{SecureRandom.hex(4)}",
      author: accounts(:alice),
      price: 5,
      listing_status: "listed"
    )

    version = SkillVersion.create!(skill: skill, version: "1.0.0", status: "draft")
    SkillArtifact.create!(
      skill_version: version,
      artifact_type: "mcp_tool_manifest",
      manifest: manifest,
      checksum: checksum
    )

    version
  end

  test "verifies a valid client-side manifest" do
    manifest = {
      "name" => "deterministic-pricing-review",
      "description" => "Review pricing payloads",
      "version" => "1.0.0",
      "runtime" => "client",
      "entrypoint" => "pricing_review.evaluate",
      "input_schema" => { "type" => "object" },
      "output_schema" => { "type" => "object" }
    }
    version = create_version_with_artifact(
      manifest: manifest,
      checksum: SkillArtifactVerificationService.checksum_for_manifest(manifest)
    )

    verification = SkillArtifactVerificationService.new(skill_version: version).call

    assert_equal "verified", verification.status
    assert version.reload.verified?
    assert verification.verified_at.present?
    assert verification.checks.values.all?
  end

  test "rejects when required fields are missing" do
    manifest = {
      "name" => "deterministic-pricing-review",
      "version" => "1.0.0",
      "runtime" => "client",
      "entrypoint" => "pricing_review.evaluate",
      "input_schema" => { "type" => "object" },
      "output_schema" => { "type" => "object" }
    }
    version = create_version_with_artifact(
      manifest: manifest,
      checksum: SkillArtifactVerificationService.checksum_for_manifest(manifest)
    )

    verification = SkillArtifactVerificationService.new(skill_version: version).call

    assert_equal "rejected", verification.status
    assert_equal "rejected", version.reload.status
    assert_equal false, verification.checks["required_fields_present"]
  end

  test "rejects non-client runtime" do
    manifest = {
      "name" => "deterministic-pricing-review",
      "description" => "Review pricing payloads",
      "version" => "1.0.0",
      "runtime" => "hosted",
      "entrypoint" => "pricing_review.evaluate",
      "input_schema" => { "type" => "object" },
      "output_schema" => { "type" => "object" }
    }
    version = create_version_with_artifact(
      manifest: manifest,
      checksum: SkillArtifactVerificationService.checksum_for_manifest(manifest)
    )

    verification = SkillArtifactVerificationService.new(skill_version: version).call

    assert_equal "rejected", verification.status
    assert_equal false, verification.checks["runtime_client"]
  end

  test "rejects checksum mismatch" do
    manifest = {
      "name" => "deterministic-pricing-review",
      "description" => "Review pricing payloads",
      "version" => "1.0.0",
      "runtime" => "client",
      "entrypoint" => "pricing_review.evaluate",
      "input_schema" => { "type" => "object" },
      "output_schema" => { "type" => "object" }
    }
    version = create_version_with_artifact(manifest: manifest, checksum: "bad-checksum")

    verification = SkillArtifactVerificationService.new(skill_version: version).call

    assert_equal "rejected", verification.status
    assert_equal false, verification.checks["checksum_matches"]
  end
end
