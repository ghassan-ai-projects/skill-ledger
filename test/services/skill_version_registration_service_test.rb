require "test_helper"

class SkillVersionRegistrationServiceTest < ActiveSupport::TestCase
  setup do
    @skill = skills(:data_analysis)
    @alice = accounts(:alice)
    @bob = accounts(:bob)
    @manifest = {
      "name" => @skill.slug,
      "description" => @skill.description,
      "version" => "2.0.0",
      "runtime" => "client",
      "entrypoint" => "data_analysis.execute",
      "input_schema" => { "type" => "object" },
      "output_schema" => { "type" => "object" },
      "files" => [
        {
          "path" => "skill/SKILL.md",
          "media_type" => "text/markdown",
          "content" => "# Data Analysis"
        }
      ]
    }
  end

  test "registers a new verified version with artifact bundle and creates a pending review" do
    service = SkillVersionRegistrationService.new(skill: @skill, author: @alice)

    assert_difference("SkillVersion.count", 1) do
      assert_difference("SkillArtifact.count", 1) do
        assert_difference("SkillVerification.count", 1) do
          assert_difference("SkillReview.count", 1) do
            result = service.call(
              version: "2.0.0",
              changelog: "Adds bundled client files",
              artifact: {
                artifact_type: "mcp_tool_manifest",
                manifest: @manifest
              }
            )

            assert_equal @skill.id, result[:skill_id]
            assert_equal "2.0.0", result[:version][:version]
            assert_equal "verified", result[:version][:status]
            assert_equal "verified", result[:verification][:status]
            assert_equal true, result[:verification][:checks]["bundled_files_valid"]
            assert_equal "pending", result[:review][:status]
          end
        end
      end
    end
  end

  test "rejects uploads from a non-author" do
    service = SkillVersionRegistrationService.new(skill: @skill, author: @bob)

    assert_no_difference("SkillVersion.count") do
      assert_raises SkillVersionRegistrationService::AuthorizationError, match: "Only the skill author" do
        service.call(
          version: "2.0.0",
          artifact: {
            manifest: @manifest
          }
        )
      end
    end
  end

  test "stores a rejected version when verification fails" do
    bad_manifest = @manifest.deep_dup
    bad_manifest["files"] = [
      {
        "path" => "skill/SKILL.md",
        "media_type" => "text/markdown"
      }
    ]

    service = SkillVersionRegistrationService.new(skill: @skill, author: @alice)

    result = service.call(
      version: "2.0.0",
      artifact: {
        manifest: bad_manifest
      }
    )

    assert_equal "rejected", result[:version][:status]
    assert_equal "rejected", result[:verification][:status]
    assert_equal false, result[:verification][:checks]["bundled_files_valid"]
  end
end
