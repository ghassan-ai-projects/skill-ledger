require "test_helper"

class PurchaseTest < ActiveSupport::TestCase
  test "generates entitlement token" do
    purchase = Purchase.create!(
      buyer: accounts(:charlie),
      skill_version: skill_versions(:data_analysis_v1),
      amount: skills(:data_analysis).price
    )

    assert purchase.entitlement_token.present?
  end

  test "requires positive amount" do
    purchase = Purchase.new(
      buyer: accounts(:charlie),
      skill_version: skill_versions(:data_analysis_v1),
      amount: 0
    )

    assert_not purchase.valid?
    assert_includes purchase.errors[:amount], "must be greater than 0"
  end

  test "requires known status" do
    purchase = Purchase.new(
      buyer: accounts(:charlie),
      skill_version: skill_versions(:data_analysis_v1),
      amount: skills(:data_analysis).price,
      status: "other"
    )

    assert_not purchase.valid?
    assert_includes purchase.errors[:status], "is not included in the list"
  end
end
