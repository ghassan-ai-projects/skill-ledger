class SkillPolicyCheckService
  MAX_ARTIFACT_BYTES = 5 * 1024 * 1024
  SECRET_PATTERNS = [
    /AKIA[0-9A-Z]{16}/,
    /-----BEGIN [A-Z ]*PRIVATE KEY-----/,
    /sk-[a-zA-Z0-9]{20,}/,
    /password\s*[:=]\s*['"]?[^\s'"]{4,}/i
  ].freeze
  GENERIC_DESCRIPTIONS = [ "test", "todo", "lorem ipsum", "tbd", "n/a", "placeholder" ].freeze
  HARD_FAIL_CHECKS = %i[no_path_traversal bundled_file_paths_allowed no_obvious_secrets].freeze

  def self.hard_fail_checks
    HARD_FAIL_CHECKS
  end

  def initialize(skill_version:)
    @skill_version = skill_version
  end

  def call
    artifact = @skill_version.skill_artifact
    manifest = artifact&.manifest || {}

    checks = {
      manifest_declares_required_fields: manifest_declares_required_fields?(manifest),
      artifact_size_within_limit: artifact_size_within_limit?(manifest),
      bundled_file_paths_allowed: bundled_file_paths_allowed?(manifest),
      permissions_declared_explicitly: permissions_declared_explicitly?(manifest),
      no_path_traversal: no_path_traversal?(manifest),
      no_obvious_secrets: no_obvious_secrets?(manifest),
      description_and_name_consistent: description_and_name_consistent?(manifest)
    }

    {
      passed: checks.values.all?,
      hard_failed: checks.any? { |name, passed| !passed && HARD_FAIL_CHECKS.include?(name) },
      checks: checks
    }
  end

  private

  def manifest_declares_required_fields?(manifest)
    SkillArtifactVerificationService::REQUIRED_MANIFEST_FIELDS.all? { |field| manifest[field].present? }
  end

  def artifact_size_within_limit?(manifest)
    SkillArtifactVerificationService.canonical_manifest_json(manifest).bytesize <= MAX_ARTIFACT_BYTES
  end

  def files(manifest)
    Array(manifest["files"])
  end

  def bundled_file_paths_allowed?(manifest)
    files(manifest).all? do |file|
      path = file.is_a?(Hash) ? file["path"] : nil
      path.present? && !path.start_with?("/") && !path.include?("..")
    end
  end

  def no_path_traversal?(manifest)
    files(manifest).none? do |file|
      path = file.is_a?(Hash) ? file["path"].to_s : ""
      path.include?("..") || path.start_with?("/")
    end
  end

  def permissions_declared_explicitly?(manifest)
    manifest.key?("permissions") && manifest["permissions"].present?
  end

  def no_obvious_secrets?(manifest)
    haystacks = [ manifest.to_s ] + files(manifest).map { |file| file.is_a?(Hash) ? file["content"].to_s : "" }

    haystacks.none? { |text| SECRET_PATTERNS.any? { |pattern| text.match?(pattern) } }
  end

  def description_and_name_consistent?(manifest)
    name = manifest["name"].to_s.strip.downcase
    description = manifest["description"].to_s.strip.downcase

    return false if name.blank? || description.blank?
    return false if GENERIC_DESCRIPTIONS.include?(name) || GENERIC_DESCRIPTIONS.include?(description)

    true
  end
end
