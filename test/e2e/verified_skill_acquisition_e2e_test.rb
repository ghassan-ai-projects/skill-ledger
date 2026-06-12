require "test_helper"

class VerifiedSkillAcquisitionE2ETest < ActionDispatch::IntegrationTest
  test "buyer agent can discover, purchase, and acquire a verified skill for local execution" do
    create_verified_skill_listing(
      name: "Deterministic Pricing Review",
      slug: "deterministic-pricing-review",
      author: accounts(:alice),
      price: 35,
      description: "Review a pricing payload for deterministic rule violations."
    )

    buyer = accounts(:charlie)
    author = accounts(:alice)
    buyer_starting_balance = buyer.balance
    author_starting_balance = author.balance

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "skills-list-1",
           method: "skills/list"
         },
         headers: headers_with_auth(buyer), as: :json

    assert_response :success
    list_body = response.parsed_body

    assert_equal "2.0", list_body["jsonrpc"]
    assert_equal "skills-list-1", list_body["id"]
    assert list_body["result"].key?("skills")

    verified_skill = list_body["result"]["skills"].find { |skill| skill["slug"] == "deterministic-pricing-review" }
    assert_not_nil verified_skill
    assert_equal true, verified_skill["verification"]["publicly_listed"]
    assert_equal "verified", verified_skill["verification"]["status"]
    assert_equal "mcp_tool_manifest", verified_skill["latest_version"]["artifact_type"]
    assert_equal "1.0.0", verified_skill["latest_version"]["version"]

    assert_difference("LedgerEntry.count", 1) do
      post "/api/v1/mcp",
           params: {
             jsonrpc: "2.0",
             id: "skills-purchase-1",
             method: "skills/purchase",
             params: {
               skill_id: verified_skill["id"],
               version: verified_skill["latest_version"]["version"]
             }
           },
           headers: headers_with_auth(buyer), as: :json
    end

    assert_response :success
    purchase_body = response.parsed_body

    assert_equal "2.0", purchase_body["jsonrpc"]
    assert_equal "skills-purchase-1", purchase_body["id"]
    assert_equal "paid", purchase_body["result"]["purchase"]["status"]
    assert purchase_body["result"]["purchase"]["id"].present?

    purchase_amount = BigDecimal(purchase_body["result"]["purchase"]["amount"].to_s)
    assert_equal buyer_starting_balance - purchase_amount, buyer.reload.balance
    assert_equal author_starting_balance + purchase_amount, author.reload.balance
    purchase_id = purchase_body["result"]["purchase"]["id"]

    assert_no_difference("LedgerEntry.count") do
      post "/api/v1/mcp",
           params: {
             jsonrpc: "2.0",
             id: "skills-purchase-retry-1",
             method: "skills/purchase",
             params: {
               skill_id: verified_skill["id"],
               version: verified_skill["latest_version"]["version"]
             }
           },
           headers: headers_with_auth(buyer), as: :json
    end

    assert_response :success
    retry_body = response.parsed_body
    assert_equal purchase_id, retry_body["result"]["purchase"]["id"]
    assert_equal buyer_starting_balance - purchase_amount, buyer.reload.balance
    assert_equal author_starting_balance + purchase_amount, author.reload.balance

    assert_no_difference("LedgerEntry.count") do
      post "/api/v1/mcp",
           params: {
             jsonrpc: "2.0",
             id: "skills-acquire-1",
             method: "skills/acquire",
             params: {
               purchase_id: purchase_id
             }
           },
           headers: headers_with_auth(buyer), as: :json
    end

    assert_response :success
    acquire_body = response.parsed_body

    assert_equal "2.0", acquire_body["jsonrpc"]
    assert_equal "skills-acquire-1", acquire_body["id"]

    artifact = acquire_body["result"]["artifact"]
    verification = acquire_body["result"]["verification"]
    entitlement = acquire_body["result"]["entitlement"]

    assert_equal "mcp_tool_manifest", artifact["type"]
    assert artifact["checksum"].present?
    assert artifact["manifest"].present?
    assert_equal "deterministic-pricing-review", artifact["manifest"]["name"]
    assert_equal verified_skill["latest_version"]["version"], artifact["manifest"]["version"]
    assert_equal "client", artifact["manifest"]["runtime"]
    assert artifact["manifest"]["entrypoint"].present?
    assert_equal "verified", verification["status"]
    assert_equal true, verification["publicly_listed"]
    assert verification["checks"].present?
    assert entitlement["acquired_at"].present?
    assert_equal buyer.id, entitlement["buyer_id"]
    assert_equal purchase_id, entitlement["purchase_id"]
  end
end
