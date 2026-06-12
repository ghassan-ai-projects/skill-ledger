require "test_helper"

class Api::V1::McpControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = accounts(:alice)
    @charlie = accounts(:charlie)
    @data_analysis = skills(:data_analysis)
    @pricing_skill = create_verified_skill_listing(
      name: "Deterministic Pricing Review",
      slug: "deterministic-pricing-review",
      author: @alice,
      price: 35,
      description: "Review a pricing payload for deterministic rule violations."
    )
  end

  test "POST /api/v1/mcp returns JSON-RPC error for unknown method" do
    post api_v1_mcp_url,
         params: {
           jsonrpc: "2.0",
           id: "req-3",
           method: "unknown/method"
         },
         headers: headers_with_auth(@charlie), as: :json

    assert_response :unprocessable_entity
    body = response.parsed_body
    assert_equal "2.0", body["jsonrpc"]
    assert_equal "req-3", body["id"]
    assert_equal(-32601, body["error"]["code"])
  end

  test "POST /api/v1/mcp lists only publicly listed verified skills for acquisition" do
    post api_v1_mcp_url,
         params: {
           jsonrpc: "2.0",
           id: "skills-list",
           method: "skills/list"
         },
         headers: headers_with_auth(@charlie), as: :json

    assert_response :success
    body = response.parsed_body

    slugs = body["result"]["skills"].map { |skill| skill["slug"] }
    assert_includes slugs, "data-analysis"
    assert_includes slugs, "deterministic-pricing-review"
    assert_not_includes slugs, "code-review"

    pricing_skill = body["result"]["skills"].find { |skill| skill["slug"] == "deterministic-pricing-review" }
    assert_equal "verified", pricing_skill["verification"]["status"]
    assert_equal true, pricing_skill["verification"]["publicly_listed"]
    assert_equal "1.0.0", pricing_skill["latest_version"]["version"]
    assert_equal "mcp_tool_manifest", pricing_skill["latest_version"]["artifact_type"]
  end

  test "POST /api/v1/mcp gets a verified skill detail" do
    post api_v1_mcp_url,
         params: {
           jsonrpc: "2.0",
             id: "skills-get",
             method: "skills/get",
             params: {
               skill_id: @pricing_skill[:skill].id
             }
         },
         headers: headers_with_auth(@charlie), as: :json

    assert_response :success
    body = response.parsed_body

    assert_equal "deterministic-pricing-review", body["result"]["skill"]["slug"]
    assert_equal "pricing_review.evaluate", body["result"]["skill"]["manifest_summary"]["entrypoint"]
    assert_equal "verified", body["result"]["skill"]["verification"]["status"]
  end

  test "POST /api/v1/mcp purchases a verified skill once" do
    assert_difference("Purchase.count", 1) do
      assert_difference("LedgerEntry.count", 1) do
        post api_v1_mcp_url,
             params: {
               jsonrpc: "2.0",
               id: "skills-purchase",
               method: "skills/purchase",
               params: {
                   skill_id: @pricing_skill[:skill].id,
                 version: "1.0.0"
               }
             },
             headers: headers_with_auth(@charlie), as: :json
      end
    end

    assert_response :success
    body = response.parsed_body
    assert_equal "paid", body["result"]["purchase"]["status"]
    assert_equal 35.0, body["result"]["purchase"]["amount"]
  end

  test "POST /api/v1/mcp acquire returns artifact without executing" do
    purchase = SkillPurchaseService.new(buyer: @charlie).call(
      skill_id: @pricing_skill[:skill].id,
      version: "1.0.0"
    )

    assert_no_difference("LedgerEntry.count") do
      post api_v1_mcp_url,
           params: {
             jsonrpc: "2.0",
             id: "skills-acquire",
             method: "skills/acquire",
             params: {
               purchase_id: purchase.id
             }
           },
           headers: headers_with_auth(@charlie), as: :json
    end

    assert_response :success
    body = response.parsed_body
    assert_equal "mcp_tool_manifest", body["result"]["artifact"]["type"]
    assert_equal "deterministic-pricing-review", body["result"]["artifact"]["manifest"]["name"]
    assert_equal [], body["result"]["artifact"]["files"]
    assert_equal "verified", body["result"]["verification"]["status"]
  end
end
