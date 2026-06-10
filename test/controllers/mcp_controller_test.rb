require "test_helper"

class Api::V1::McpControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = accounts(:alice)
    @charlie = accounts(:charlie)
    @data_analysis = skills(:data_analysis)
    @code_review = skills(:code_review)
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
    assert_equal 2, body["result"]["tools"].length

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
end
