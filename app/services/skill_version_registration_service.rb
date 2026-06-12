class SkillVersionRegistrationService
  class Error < StandardError; end
  class AuthorizationError < Error; end

  def initialize(skill:, author:)
    @skill = skill
    @author = author
  end

  def call(version:, changelog: nil, artifact:)
    raise AuthorizationError, "Only the skill author can upload versions" unless @skill.author_id == @author.id

    manifest = artifact.fetch(:manifest)
    artifact_type = artifact[:artifact_type].presence || "mcp_tool_manifest"

    skill_version = nil
    created_artifact = nil
    verification = nil

    SkillVersion.transaction do
      skill_version = SkillVersion.create!(
        skill: @skill,
        version: version,
        changelog: changelog,
        status: "draft"
      )

      created_artifact = SkillArtifact.create!(
        skill_version: skill_version,
        artifact_type: artifact_type,
        manifest: manifest,
        checksum: SkillArtifactVerificationService.checksum_for_manifest(manifest)
      )

      verification = SkillArtifactVerificationService.new(skill_version: skill_version).call
    end

    {
      skill_id: @skill.id,
      version: {
        id: skill_version.id,
        version: skill_version.version,
        changelog: skill_version.changelog,
        status: skill_version.status
      },
      artifact: {
        artifact_type: created_artifact.artifact_type,
        checksum: created_artifact.checksum,
        manifest: created_artifact.manifest
      },
      verification: {
        status: verification.status,
        checks: verification.checks,
        verified_at: verification.verified_at,
        failure_reason: verification.failure_reason
      }
    }
  rescue KeyError => e
    raise Error, e.message
  rescue ActiveRecord::RecordInvalid => e
    raise Error, e.record.errors.full_messages.to_sentence
  end
end
