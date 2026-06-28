class SkillAcquisitionService
  class Error < StandardError; end

  def initialize(buyer:)
    @buyer = buyer
  end

  def call(purchase_id:)
    purchase = Purchase.includes(skill_version: [ :skill_artifact, :skill_verification, { skill: :author } ]).find(purchase_id)
    raise Error, "Purchase does not belong to current account" unless purchase.buyer_id == @buyer.id
    raise Error, "Purchase is not paid" unless purchase.paid?

    purchase.update!(acquired_at: Time.current) if purchase.acquired_at.nil?

    artifact = purchase.skill_version.skill_artifact
    verification = purchase.skill_version.skill_verification
    review = purchase.skill_version.skill_review
    skill = purchase.skill_version.skill

    {
      artifact: {
        type: artifact.artifact_type,
        checksum: artifact.checksum,
        manifest: artifact.manifest,
        files: artifact.manifest["files"] || []
      },
      verification: {
        status: verification.status,
        publicly_listed: skill.listing_status == "listed" && SkillMarketplaceEligibilityService.eligible_for_purchase?(purchase.skill_version),
        checks: verification.checks,
        verified_at: verification.verified_at
      },
      approval: {
        status: review&.status,
        decided_at: review&.decided_at,
        revoked: SkillMarketplaceEligibilityService.version_revoked?(purchase.skill_version)
      },
      entitlement: {
        purchase_id: purchase.id,
        buyer_id: purchase.buyer_id,
        skill_id: skill.id,
        skill_version: purchase.skill_version.version,
        entitlement_token: purchase.entitlement_token,
        acquired_at: purchase.acquired_at
      }
    }
  rescue ActiveRecord::RecordInvalid => e
    raise Error, e.message
  rescue ActiveRecord::RecordNotFound
    raise Error, "Purchase not found"
  end
end
