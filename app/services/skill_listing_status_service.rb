class SkillListingStatusService
  class Error < StandardError; end
  class AuthorizationError < Error; end

  def initialize(skill:, actor:)
    @skill = skill
    @actor = actor
  end

  def call(listing_status:)
    raise AuthorizationError, "Only the skill author can change listing status" unless @skill.author_id == @actor.id
    raise Error, "Skill must have an approved version before listing publicly" if listing_status == "listed" && !SkillMarketplaceEligibilityService.eligible_for_listing?(@skill)

    @skill.update!(listing_status: listing_status)
    @skill
  rescue ActiveRecord::RecordInvalid => e
    raise Error, e.record.errors.full_messages.to_sentence
  end
end
