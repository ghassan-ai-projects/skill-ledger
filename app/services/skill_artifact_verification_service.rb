class SkillArtifactVerificationService
  REQUIRED_MANIFEST_FIELDS = %w[
    name
    description
    version
    runtime
    entrypoint
    input_schema
    output_schema
  ].freeze

  def self.canonical_manifest_json(manifest)
    JSON.generate(deep_sort(manifest))
  end

  def self.checksum_for_manifest(manifest)
    Digest::SHA256.hexdigest(canonical_manifest_json(manifest))
  end

  def self.deep_sort(value)
    case value
    when Hash
      value.keys.sort.each_with_object({}) do |key, result|
        result[key] = deep_sort(value[key])
      end
    when Array
      value.map { |item| deep_sort(item) }
    else
      value
    end
  end

  def initialize(skill_version:)
    @skill_version = skill_version
  end

  def call
    artifact = @skill_version.skill_artifact
    checks = build_checks(artifact)
    status = checks.values.all? ? "verified" : "rejected"

    verification = @skill_version.skill_verification || @skill_version.build_skill_verification
    verification.update!(
      status: status,
      checks: checks,
      verified_at: (status == "verified" ? Time.current : nil),
      failure_reason: (status == "rejected" ? failure_reason_for(checks) : nil)
    )

    @skill_version.update!(status: status)
    verification
  end

  private

  def build_checks(artifact)
    manifest = artifact&.manifest

    {
      artifact_present: artifact.present?,
      artifact_type_supported: artifact.present? && SkillArtifact::ARTIFACT_TYPES.include?(artifact.artifact_type),
      manifest_valid: manifest.is_a?(Hash),
      required_fields_present: required_fields_present?(manifest),
      runtime_client: manifest.is_a?(Hash) && manifest["runtime"] == "client",
      version_matches: manifest.is_a?(Hash) && manifest["version"] == @skill_version.version,
      checksum_matches: artifact.present? && artifact.checksum == self.class.checksum_for_manifest(manifest || {})
    }
  end

  def required_fields_present?(manifest)
    return false unless manifest.is_a?(Hash)

    REQUIRED_MANIFEST_FIELDS.all? { |field| manifest[field].present? }
  end

  def failure_reason_for(checks)
    failed_check = checks.find { |_, passed| !passed }
    return "Artifact verification failed" unless failed_check

    "#{failed_check.first.to_s.humanize} failed"
  end
end
