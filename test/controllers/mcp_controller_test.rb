require "test_helper"

class Api::V1::McpControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = accounts(:alice)
    @charlie = accounts(:charlie)
    @data_analysis = skills(:data_analysis)
    @code_review = skills(:code_review)
    @pricing_skill = create_verified_skill_listing(
      name: "Deterministic Pricing Review",
      slug: "deterministic-pricing-review",
      author: @alice,
      price_per_call: 35,
      description: "Review a pricing payload for deterministic rule violations."
    )
  end

  test "POST /api/v1/mcp lists skills as MCP tools" do
    post api_v1_mcp_url,
         params: {
           jsonrpc: "2.0",
           id: "req-1",
           method: "tools/list"
         },
         headers: headers_with_auth(@charlie), as: :json

    assert_response :success
    body = response.parsed_body

    assert_equal "2.0", body["jsonrpc"]
    assert_equal "req-1", body["id"]
    assert body["result"].key?("tools")
    assert_equal 3, body["result"]["tools"].length

    tool = body["result"]["tools"].find { |t| t["name"] == "skill.execute.#{@data_analysis.id}" }
    assert_not_nil tool
    assert_equal @data_analysis.description, tool["description"]
    assert_equal "object", tool["inputSchema"]["type"]
    assert_equal [ "numbers" ], tool["inputSchema"]["required"]
    assert_equal "array", tool["inputSchema"]["properties"]["numbers"]["type"]
  end

  test "POST /api/v1/mcp invokes built-in data analysis and returns a completed result" do
    assert_difference("Execution.count", 1) do
      assert_difference -> { @charlie.reload.balance }, -@data_analysis.price_per_call do
        assert_difference -> { @charlie.reload.escrow_balance }, 0 do
          assert_difference -> { @alice.reload.balance }, @data_analysis.price_per_call do
            assert_difference("LedgerEntry.count", 1) do
              post api_v1_mcp_url,
                   params: {
                     jsonrpc: "2.0",
                     id: "req-2",
                     method: "tools/call",
                     params: {
                       name: "skill.execute.#{@data_analysis.id}",
                       arguments: {
                         dataset_name: "weekly_sales",
                         numbers: [ 10, 20, 30, 40 ]
                       }
                     }
                   },
                   headers: headers_with_auth(@charlie), as: :json
            end
          end
        end
      end
    end

    assert_response :success
    body = response.parsed_body
    assert_equal "2.0", body["jsonrpc"]
    assert_equal "req-2", body["id"]
    assert_equal @data_analysis.id, body["result"]["execution"]["skill_id"]
    assert_equal "completed", body["result"]["execution"]["status"]
    assert_equal "text", body["result"]["content"][0]["type"]
    assert_equal 4, body["result"]["analysis"]["count"]
    assert_equal 100.0, body["result"]["analysis"]["sum"]
    assert_equal 25.0, body["result"]["analysis"]["average"]
    assert_equal 25.0, body["result"]["analysis"]["median"]

    execution = Execution.last
    assert_equal "completed", execution.status
    assert_includes execution.result, "\"dataset_name\":\"weekly_sales\""
  end

  test "POST /api/v1/mcp invokes a non-built-in skill and leaves execution pending" do
    assert_difference("Execution.count", 1) do
      assert_difference -> { @charlie.reload.balance }, -@code_review.price_per_call do
        assert_difference -> { @charlie.reload.escrow_balance }, @code_review.price_per_call do
          post api_v1_mcp_url,
               params: {
                 jsonrpc: "2.0",
                 id: "req-2b",
                 method: "tools/call",
                 params: {
                   name: "skill.execute.#{@code_review.id}",
                   arguments: {}
                 }
               },
               headers: headers_with_auth(@charlie), as: :json
        end
      end
    end

    assert_response :success
    body = response.parsed_body
    assert_equal @code_review.id, body["result"]["execution"]["skill_id"]
    assert_equal "pending", body["result"]["execution"]["status"]
    assert_nil body["result"]["analysis"]
  end

  test "POST /api/v1/mcp returns invalid params for bad built-in data analysis input" do
    assert_no_difference([ "Execution.count", "LedgerEntry.count" ]) do
      post api_v1_mcp_url,
           params: {
             jsonrpc: "2.0",
             id: "req-invalid",
             method: "tools/call",
             params: {
               name: "skill.execute.#{@data_analysis.id}",
               arguments: {
                 numbers: []
               }
             }
           },
           headers: headers_with_auth(@charlie), as: :json
    end

    assert_response :unprocessable_entity
    body = response.parsed_body
    assert_equal(-32602, body["error"]["code"])
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

  test "POST /api/v1/mcp returns JSON-RPC error for unknown tool" do
    post api_v1_mcp_url,
         params: {
           jsonrpc: "2.0",
           id: "req-4",
           method: "tools/call",
           params: {
             name: "skill.execute.99999",
             arguments: {}
           }
         },
         headers: headers_with_auth(@charlie), as: :json

    assert_response :unprocessable_entity
    body = response.parsed_body
    assert_equal(-32602, body["error"]["code"])
    assert_includes body["error"]["message"], "Unknown tool"
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
        assert_no_difference("Execution.count") do
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

    assert_no_difference([ "LedgerEntry.count", "Execution.count" ]) do
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
    assert_equal "verified", body["result"]["verification"]["status"]
    assert_nil body["result"]["execution"]
    assert_nil body["result"]["hosted_execution"]
  end
end
