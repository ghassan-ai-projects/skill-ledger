require "test_helper"

class SkillListingStatusServiceTest < ActiveSupport::TestCase
  setup do
    @author = accounts(:alice)
    @other = accounts(:bob)
    @skill = Skill.create!(
      name: "Draft Workflow",
      description: "A draft workflow",
      author: @author,
      price: 15,
      listing_status: "draft"
    )
  end

  test "author can list a skill with a verified version" do
    create_verified_version_for(@skill, version: "1.0.0")

    updated_skill = SkillListingStatusService.new(skill: @skill, actor: @author).call(listing_status: "listed")

    assert_equal "listed", updated_skill.listing_status
  end

  test "rejects public listing without a verified version" do
    assert_raises SkillListingStatusService::Error, match: "verified version" do
      SkillListingStatusService.new(skill: @skill, actor: @author).call(listing_status: "listed")
    end
  end

  test "rejects non-author status changes" do
    create_verified_version_for(@skill, version: "1.0.0")

    assert_raises SkillListingStatusService::AuthorizationError, match: "Only the skill author" do
      SkillListingStatusService.new(skill: @skill, actor: @other).call(listing_status: "listed")
    end
  end

  private

  def create_verified_version_for(skill, version:)
    skill_version = SkillVersion.create!(skill: skill, version: version, status: "draft")
    manifest = {
      "name" => skill.slug,
      "description" => skill.description,
      "version" => version,
      "runtime" => "client",
      "entrypoint" => "workflow.execute",
      "input_schema" => { "type" => "object" },
      "output_schema" => { "type" => "object" }
    }

    SkillArtifact.create!(
      skill_version: skill_version,
      artifact_type: "mcp_tool_manifest",
      manifest: manifest,
      checksum: SkillArtifactVerificationService.checksum_for_manifest(manifest)
    )

    SkillArtifactVerificationService.new(skill_version: skill_version).call
  end
end
