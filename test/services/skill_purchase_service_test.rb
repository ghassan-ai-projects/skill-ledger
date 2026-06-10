require "test_helper"

class SkillPurchaseServiceTest < ActiveSupport::TestCase
  setup do
    @buyer = accounts(:charlie)
    @author = accounts(:alice)
    @service = SkillPurchaseService.new(buyer: @buyer)
    @pricing_skill = create_verified_skill_listing(
      name: "Deterministic Pricing Review",
      slug: "deterministic-pricing-review",
      author: @author,
      price: 35,
      description: "Review a pricing payload for deterministic rule violations."
    )
  end

  test "creates a purchase and transfers funds once" do
    skill = @pricing_skill[:skill]
    version = @pricing_skill[:version]

    assert_difference("Purchase.count", 1) do
      assert_difference("LedgerEntry.count", 1) do
        purchase = @service.call(skill_id: skill.id, version: version.version)

        assert_equal "paid", purchase.status
        assert_equal @buyer.id, purchase.buyer_id
        assert_equal version.id, purchase.skill_version_id
      end
    end

    assert_equal 215.to_d, @buyer.reload.balance
    assert_equal 1035.to_d, @author.reload.balance
  end

  test "returns existing paid purchase on retry without charging again" do
    skill = @pricing_skill[:skill]
    version = @pricing_skill[:version]

    first_purchase = @service.call(skill_id: skill.id, version: version.version)

    assert_no_difference([ "Purchase.count", "LedgerEntry.count" ]) do
      second_purchase = @service.call(skill_id: skill.id, version: version.version)
      assert_equal first_purchase.id, second_purchase.id
    end

    assert_equal 215.to_d, @buyer.reload.balance
    assert_equal 1035.to_d, @author.reload.balance
  end

  test "rejects self purchase" do
    service = SkillPurchaseService.new(buyer: @author)

    assert_raises SkillPurchaseService::Error, match: "own skill" do
      service.call(skill_id: @pricing_skill[:skill].id, version: "1.0.0")
    end
  end

  test "rejects unverified versions" do
    assert_raises SkillPurchaseService::Error, match: "not verified" do
      @service.call(skill_id: skills(:code_review).id, version: skill_versions(:code_review_v1).version)
    end
  end

  test "rejects insufficient balance" do
    expensive_skill = Skill.create!(
      name: "Premium Verification Skill",
      author: @author,
      price: 999,
      listing_status: "listed"
    )
    expensive_version = SkillVersion.create!(skill: expensive_skill, version: "1.0.0", status: "verified")
    manifest = {
      "name" => "premium-verification-skill",
      "description" => "Very expensive skill",
      "version" => "1.0.0",
      "runtime" => "client",
      "entrypoint" => "premium.execute",
      "input_schema" => { "type" => "object" },
      "output_schema" => { "type" => "object" }
    }
    SkillArtifact.create!(
      skill_version: expensive_version,
      artifact_type: "mcp_tool_manifest",
      manifest: manifest,
      checksum: SkillArtifactVerificationService.checksum_for_manifest(manifest)
    )
    SkillVerification.create!(
      skill_version: expensive_version,
      status: "verified",
      checks: { "checksum_matches" => true },
      verified_at: Time.current
    )

    assert_raises SkillPurchaseService::Error, match: "insufficient balance" do
      @service.call(skill_id: expensive_skill.id, version: expensive_version.version)
    end
  end
end
