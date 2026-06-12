require "test_helper"

class SkillAcquisitionServiceTest < ActiveSupport::TestCase
  setup do
    @buyer = accounts(:charlie)
    @pricing_skill = create_verified_skill_listing(
      name: "Deterministic Pricing Review",
      slug: "deterministic-pricing-review",
      author: accounts(:alice),
      price: 35,
      description: "Review a pricing payload for deterministic rule violations."
    )
    @service = SkillAcquisitionService.new(buyer: @buyer)
    @purchase = Purchase.create!(
      buyer: @buyer,
      skill_version: @pricing_skill[:version],
      amount: @pricing_skill[:skill].price,
      status: "paid"
    )
  end

  test "returns verified artifact payload for owner" do
    result = @service.call(purchase_id: @purchase.id)

    assert_equal "mcp_tool_manifest", result[:artifact][:type]
    assert_equal "deterministic-pricing-review", result[:artifact][:manifest]["name"]
    assert_equal [], result[:artifact][:files]
    assert_equal "verified", result[:verification][:status]
    assert_equal @purchase.id, result[:entitlement][:purchase_id]
    assert result[:entitlement][:acquired_at].present?
  end

  test "sets acquired timestamp only once" do
    first_result = @service.call(purchase_id: @purchase.id)
    first_acquired_at = first_result[:entitlement][:acquired_at]

    travel 1.second do
      second_result = @service.call(purchase_id: @purchase.id)
      assert_equal first_acquired_at, second_result[:entitlement][:acquired_at]
    end
  end

  test "rejects other buyer purchase" do
    other_purchase = Purchase.create!(
      buyer: accounts(:bob),
      skill_version: @pricing_skill[:version],
      amount: @pricing_skill[:skill].price,
      status: "paid"
    )

    assert_raises SkillAcquisitionService::Error, match: "does not belong" do
      @service.call(purchase_id: other_purchase.id)
    end
  end

  test "does not create ledger entries while acquiring" do
    assert_no_difference("LedgerEntry.count") do
      @service.call(purchase_id: @purchase.id)
    end
  end
end
