class SkillMarketplaceEligibilityService
  def self.version_approved?(skill_version)
    return false unless skill_version
    return false unless skill_version.status == "verified"
    return false unless skill_version.skill_verification&.status == "verified"

    skill_version.skill_review&.status == "approved"
  end

  def self.version_revoked?(skill_version)
    skill_version&.skill_review&.status == "revoked"
  end

  def self.approved_version_for(skill)
    skill.skill_versions.find { |version| version_approved?(version) }
  end

  def self.eligible_for_listing?(skill)
    approved_version_for(skill).present?
  end

  def self.eligible_for_purchase?(skill_version)
    version_approved?(skill_version)
  end
end
