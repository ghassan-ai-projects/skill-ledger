require "test_helper"

class SkillReviewSubmissionServiceTest < ActiveSupport::TestCase
  setup do
    @skill = Skill.create!(name: "Review Submission Skill", author: accounts(:alice), price: 10, listing_status: "draft")
    @version = SkillVersion.create!(skill: @skill, version: "1.0.0", status: "verified")
  end

  def build_artifact(manifest)
    SkillArtifact.create!(
      skill_version: @version,
      artifact_type: "mcp_tool_manifest",
      manifest: manifest,
      checksum: SkillArtifactVerificationService.checksum_for_manifest(manifest)
    )
  end

  def clean_manifest
    {
      "name" => @skill.slug,
      "description" => "A real description of what this skill does",
      "version" => "1.0.0",
      "runtime" => "client",
      "entrypoint" => "review.execute",
      "input_schema" => { "type" => "object" },
      "output_schema" => { "type" => "object" },
      "permissions" => { "network_access" => "none" }
    }
  end

  test "creates a pending review when policy checks pass" do
    build_artifact(clean_manifest)

    assert_difference("SkillReview.count", 1) do
      review = SkillReviewSubmissionService.new(skill_version: @version).call

      assert_equal "pending", review.status
      assert_equal "automated", review.review_type
      assert_not_nil review.submitted_at
    end
  end

  test "auto-rejects when policy checks hard fail" do
    build_artifact(clean_manifest.merge("files" => [
      { "path" => "../../etc/passwd", "media_type" => "text/plain", "content" => "x" }
    ]))

    review = SkillReviewSubmissionService.new(skill_version: @version).call

    assert_equal "rejected", review.status
    assert_equal "automated", review.review_type
    assert_match(/Automated policy check failed/, review.decision_reason)
    assert_not_nil review.decided_at
  end

  test "is idempotent when a decided review already exists" do
    build_artifact(clean_manifest)
    first = SkillReviewSubmissionService.new(skill_version: @version).call
    SkillApprovalService.new(skill_review: first, reviewer_account: admin_account).call(decision: "approve")

    assert_no_difference("SkillReview.count") do
      second = SkillReviewSubmissionService.new(skill_version: @version).call
      assert_equal "approved", second.status
    end
  end
end
