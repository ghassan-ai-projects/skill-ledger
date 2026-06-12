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

  test "POST /api/v1/mcp creates a draft skill for the authenticated author" do
    assert_difference("Skill.count", 1) do
      post api_v1_mcp_url,
           params: {
             jsonrpc: "2.0",
             id: "skills-create",
             method: "skills/create",
             params: {
               name: "Publisher Control Plane",
               description: "Author-side MCP publishing helper",
               price: 15.5
             }
           },
           headers: headers_with_auth(@alice), as: :json
    end

    assert_response :success
    body = response.parsed_body

    assert_equal "Publisher Control Plane", body["result"]["skill"]["name"]
    assert_equal "publisher-control-plane", body["result"]["skill"]["slug"]
    assert_equal "draft", body["result"]["skill"]["listing_status"]
    assert_equal @alice.id, body["result"]["skill"]["author"]["id"]
    assert_equal [], body["result"]["skill"]["versions"]
    assert_equal 0, body["result"]["skill"]["purchase_summary"]["paid_purchase_count"]
  end

  test "POST /api/v1/mcp rejects creating a listed skill before a verified version exists" do
    assert_no_difference("Skill.count") do
      post api_v1_mcp_url,
           params: {
             jsonrpc: "2.0",
             id: "skills-create-listed",
             method: "skills/create",
             params: {
               name: "Too Early Listing",
               price: 20,
               listing_status: "listed"
             }
           },
           headers: headers_with_auth(@alice), as: :json
    end

    assert_response :unprocessable_entity
    body = response.parsed_body
    assert_equal(-32602, body["error"]["code"])
    assert_includes body["error"]["message"], "verified version"
  end

  test "POST /api/v1/mcp lists only the authenticated author's skills with purchase summary and versions" do
    SkillVersionRegistrationService.new(skill: @pricing_skill[:skill], author: @alice).call(
      version: "2.0.0",
      artifact: {
        manifest: {
          "name" => @pricing_skill[:skill].slug,
          "description" => @pricing_skill[:skill].description,
          "version" => "2.0.0",
          "runtime" => "client",
          "entrypoint" => "pricing_review.evaluate_v2",
          "input_schema" => { "type" => "object" },
          "output_schema" => { "type" => "object" },
          "files" => [
            {
              "path" => "skill/SKILL.md",
              "media_type" => "text/markdown"
            }
          ]
        }
      }
    )

    SkillPurchaseService.new(buyer: @charlie).call(
      skill_id: @pricing_skill[:skill].id,
      version: "1.0.0"
    )

    post api_v1_mcp_url,
         params: {
           jsonrpc: "2.0",
           id: "skills-mine-list",
           method: "skills/mine.list"
         },
         headers: headers_with_auth(@alice), as: :json

    assert_response :success
    body = response.parsed_body

    slugs = body["result"]["skills"].map { |skill| skill["slug"] }
    assert_includes slugs, "data-analysis"
    assert_includes slugs, "deterministic-pricing-review"
    assert_not_includes slugs, "code-review"

    owned_skill = body["result"]["skills"].find { |skill| skill["slug"] == "deterministic-pricing-review" }
    assert_equal 1, owned_skill["purchase_summary"]["paid_purchase_count"]
    assert_equal 35.0, owned_skill["purchase_summary"]["gross_revenue"]
    assert_equal "2.0.0", owned_skill["latest_version"]["version"]
    assert_equal [ "2.0.0", "1.0.0" ], owned_skill["versions"].map { |version| version["version"] }
    assert_equal "rejected", owned_skill["versions"].first["verification_status"]
  end

  test "POST /api/v1/mcp publishes a version for an owned skill" do
    draft_skill = Skill.create!(
      name: "Publisher MCP Flow",
      description: "Version publishing over MCP",
      author: @alice,
      price: 21,
      listing_status: "draft"
    )

    assert_difference("SkillVersion.count", 1) do
      post api_v1_mcp_url,
           params: {
             jsonrpc: "2.0",
             id: "skills-version-publish",
             method: "skills/version.publish",
             params: {
               skill_id: draft_skill.id,
               version: "1.0.0",
               changelog: "Initial MCP release",
               artifact: {
                 artifact_type: "mcp_tool_manifest",
                 manifest: {
                   name: draft_skill.slug,
                   description: draft_skill.description,
                   version: "1.0.0",
                   runtime: "client",
                   entrypoint: "publisher_mcp_flow.run",
                   input_schema: { type: "object" },
                   output_schema: { type: "object" },
                   files: [
                     {
                       path: "skill/SKILL.md",
                       media_type: "text/markdown",
                       content: "# Publisher MCP Flow"
                     }
                   ]
                 }
               }
             }
           },
           headers: headers_with_auth(@alice), as: :json
    end

    assert_response :success
    body = response.parsed_body
    assert_equal draft_skill.id, body["result"]["publication"]["skill_id"]
    assert_equal "1.0.0", body["result"]["publication"]["version"]["version"]
    assert_equal "verified", body["result"]["publication"]["version"]["status"]
    assert_equal "verified", body["result"]["publication"]["verification"]["status"]
  end

  test "POST /api/v1/mcp rejects version publish for someone else's skill" do
    post api_v1_mcp_url,
         params: {
           jsonrpc: "2.0",
           id: "skills-version-publish-forbidden",
           method: "skills/version.publish",
           params: {
             skill_id: @pricing_skill[:skill].id,
             version: "2.0.0",
             artifact: {
               manifest: {
                 name: @pricing_skill[:skill].slug,
                 description: @pricing_skill[:skill].description,
                 version: "2.0.0",
                 runtime: "client",
                 entrypoint: "pricing_review.evaluate_v2",
                 input_schema: { type: "object" },
                 output_schema: { type: "object" },
                 files: []
               }
             }
           }
         },
         headers: headers_with_auth(@charlie), as: :json

    assert_response :unprocessable_entity
    body = response.parsed_body
    assert_equal(-32001, body["error"]["code"])
    assert_includes body["error"]["message"], "do not own"
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

  test "POST /api/v1/mcp gets an owned rejected version detail" do
    SkillVersionRegistrationService.new(skill: @pricing_skill[:skill], author: @alice).call(
      version: "2.0.0",
      artifact: {
        manifest: {
          "name" => @pricing_skill[:skill].slug,
          "description" => @pricing_skill[:skill].description,
          "version" => "2.0.0",
          "runtime" => "client",
          "entrypoint" => "pricing_review.evaluate_v2",
          "input_schema" => { "type" => "object" },
          "output_schema" => { "type" => "object" },
          "files" => [
            {
              "path" => "skill/SKILL.md",
              "media_type" => "text/markdown"
            }
          ]
        }
      }
    )

    post api_v1_mcp_url,
         params: {
           jsonrpc: "2.0",
           id: "skills-version-get",
           method: "skills/version.get",
           params: {
             skill_id: @pricing_skill[:skill].id,
             version: "2.0.0"
           }
         },
         headers: headers_with_auth(@alice), as: :json

    assert_response :success
    body = response.parsed_body

    assert_equal "deterministic-pricing-review", body["result"]["version"]["skill"]["slug"]
    assert_equal "2.0.0", body["result"]["version"]["version"]
    assert_equal "rejected", body["result"]["version"]["status"]
    assert_equal "rejected", body["result"]["version"]["verification"]["status"]
    assert_equal false, body["result"]["version"]["verification"]["checks"]["bundled_files_valid"]
    assert_equal 1, body["result"]["version"]["artifact"]["file_count"]
  end

  test "POST /api/v1/mcp changes listing status for an owned skill" do
    post api_v1_mcp_url,
         params: {
           jsonrpc: "2.0",
           id: "skills-listing-set-status",
           method: "skills/listing.set_status",
           params: {
             skill_id: @pricing_skill[:skill].id,
             listing_status: "suspended"
           }
         },
         headers: headers_with_auth(@alice), as: :json

    assert_response :success
    body = response.parsed_body

    assert_equal "suspended", body["result"]["skill"]["listing_status"]
    assert_equal @pricing_skill[:skill].id, body["result"]["skill"]["id"]
  end

  test "POST /api/v1/mcp rejects listing status change without a verified version" do
    draft_skill = Skill.create!(
      name: "Never Listed",
      description: "No verified versions yet",
      author: @alice,
      price: 12,
      listing_status: "draft"
    )

    post api_v1_mcp_url,
         params: {
           jsonrpc: "2.0",
           id: "skills-listing-set-status-invalid",
           method: "skills/listing.set_status",
           params: {
             skill_id: draft_skill.id,
             listing_status: "listed"
           }
         },
         headers: headers_with_auth(@alice), as: :json

    assert_response :unprocessable_entity
    body = response.parsed_body
    assert_equal(-32602, body["error"]["code"])
    assert_includes body["error"]["message"], "verified version"
  end

  test "POST /api/v1/mcp rejects author version lookup for someone else's skill" do
    post api_v1_mcp_url,
         params: {
           jsonrpc: "2.0",
           id: "skills-version-get-forbidden",
           method: "skills/version.get",
           params: {
             skill_id: @pricing_skill[:skill].id,
             version: "1.0.0"
           }
         },
         headers: headers_with_auth(@charlie), as: :json

    assert_response :unprocessable_entity
    body = response.parsed_body
    assert_equal(-32001, body["error"]["code"])
    assert_includes body["error"]["message"], "do not own"
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
