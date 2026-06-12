class SkillListingStatusService
  class Error < StandardError; end
  class AuthorizationError < Error; end

  def initialize(skill:, actor:)
    @skill = skill
    @actor = actor
  end

  def call(listing_status:)
    raise AuthorizationError, "Only the skill author can change listing status" unless @skill.author_id == @actor.id
    raise Error, "Skill must have a verified version before listing publicly" if listing_status == "listed" && !verified_version_exists?

    @skill.update!(listing_status: listing_status)
    @skill
  rescue ActiveRecord::RecordInvalid => e
    raise Error, e.record.errors.full_messages.to_sentence
  end

  private

  def verified_version_exists?
    @skill.skill_versions.joins(:skill_verification)
          .where(status: "verified", skill_verifications: { status: "verified" })
          .exists?
  end
end
