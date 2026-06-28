require "test_helper"

class McpPublisherInventoryE2ETest < ActionDispatch::IntegrationTest
  ALMS_SHARED_FILES = [
    "prompts/README.md",
    "prompts/prompts.md",
    "scripts/alms_mcp.py",
    "scripts/fetch-remote-learnings.py",
    "scripts/push-local-learnings.py"
  ].freeze

  test "author can manage draft inventory, publish a version, and list it publicly through MCP" do
    author = accounts(:alice)
    buyer = accounts(:charlie)

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "publisher-create-skill",
           method: "skills/create",
           params: {
             name: "ALMS Default Learning Workflow",
             description: "Default ALMS-connected learning workflow for new agents.",
             price: 55
           }
         },
         headers: headers_with_auth(author), as: :json

    assert_response :success
    created_skill = response.parsed_body.dig("result", "skill")
    skill_id = created_skill["id"]
    skill_slug = created_skill["slug"]

    assert_equal "draft", created_skill["listing_status"]
    assert_equal [], created_skill["versions"]
    assert_equal 0, created_skill.dig("purchase_summary", "paid_purchase_count")

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "publisher-mine-list-initial",
           method: "skills/mine.list"
         },
         headers: headers_with_auth(author), as: :json

    assert_response :success
    mine_list_before_publish = response.parsed_body.dig("result", "skills")
    created_inventory_skill = mine_list_before_publish.find { |skill| skill["id"] == skill_id }

    assert_not_nil created_inventory_skill
    assert_equal "draft", created_inventory_skill["listing_status"]
    assert_equal [], created_inventory_skill["versions"]

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "publisher-version-publish",
           method: "skills/version.publish",
           params: {
             skill_id: skill_id,
             version: "1.0.0",
             changelog: "Initial ALMS learning workflow release",
             artifact: {
               artifact_type: "mcp_tool_manifest",
               manifest: alms_manifest(
                 slug: skill_slug,
                 version: "1.0.0",
                 entrypoint: "scripts/push-local-learnings.py",
                 files: build_alms_file_bundle("skill/alms-learning-SKILL-v2.1.md", *ALMS_SHARED_FILES)
               )
             }
           }
         },
         headers: headers_with_auth(author), as: :json

    assert_response :success
    publish_body = response.parsed_body.dig("result", "publication")
    assert_equal "verified", publish_body.dig("version", "status")
    assert_equal "verified", publish_body.dig("verification", "status")

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "publisher-version-get",
           method: "skills/version.get",
           params: {
             skill_id: skill_id,
             version: "1.0.0"
           }
         },
         headers: headers_with_auth(author), as: :json

    assert_response :success
    version_body = response.parsed_body.dig("result", "version")

    assert_equal skill_slug, version_body.dig("skill", "slug")
    assert_equal "draft", version_body.dig("skill", "listing_status")
    assert_equal "1.0.0", version_body["version"]
    assert_equal "verified", version_body["status"]
    assert_equal "verified", version_body.dig("verification", "status")
    assert_equal "mcp_tool_manifest", version_body.dig("artifact", "artifact_type")
    assert_equal 6, version_body.dig("artifact", "file_count")

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "publisher-mine-list-after-publish",
           method: "skills/mine.list"
         },
         headers: headers_with_auth(author), as: :json

    assert_response :success
    mine_list_after_publish = response.parsed_body.dig("result", "skills")
    published_inventory_skill = mine_list_after_publish.find { |skill| skill["id"] == skill_id }

    assert_not_nil published_inventory_skill
    assert_equal "1.0.0", published_inventory_skill.dig("latest_version", "version")
    assert_equal "verified", published_inventory_skill.dig("latest_version", "verification_status")
    assert_equal [ "1.0.0" ], published_inventory_skill["versions"].map { |version| version["version"] }

    skill_version = SkillVersion.find_by(skill_id: skill_id, version: "1.0.0")
    review = skill_version.skill_review
    SkillApprovalService.new(skill_review: review, reviewer_account: admin_account).call(decision: "approve")

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "publisher-listing-set-status",
           method: "skills/listing.set_status",
           params: {
             skill_id: skill_id,
             listing_status: "listed"
           }
         },
          headers: headers_with_auth(author), as: :json

    assert_response :success
    assert_equal "listed", response.parsed_body.dig("result", "skill", "listing_status")

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "buyer-list-after-author-publish",
           method: "skills/list"
         },
         headers: headers_with_auth(buyer), as: :json

    assert_response :success
    listed_skill = response.parsed_body.dig("result", "skills").find { |skill| skill["id"] == skill_id }

    assert_not_nil listed_skill
    assert_equal skill_slug, listed_skill["slug"]
    assert_equal "1.0.0", listed_skill.dig("latest_version", "version")
    assert_equal "verified", listed_skill.dig("verification", "status")
  end

  test "author can inspect a rejected version through MCP before it is ever publicly listed" do
    author = accounts(:alice)
    buyer = accounts(:charlie)

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "publisher-create-bad-skill",
           method: "skills/create",
           params: {
             name: "Broken ALMS Workflow",
             description: "Used to verify rejected author-visible versions.",
             price: 25
           }
         },
         headers: headers_with_auth(author), as: :json

    assert_response :success
    created_skill = response.parsed_body.dig("result", "skill")
    skill_id = created_skill["id"]
    skill_slug = created_skill["slug"]

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "publisher-version-publish-rejected",
           method: "skills/version.publish",
           params: {
             skill_id: skill_id,
             version: "1.0.0",
             changelog: "Broken initial release",
             artifact: {
               artifact_type: "mcp_tool_manifest",
               manifest: alms_manifest(
                 slug: skill_slug,
                 version: "1.0.0",
                 entrypoint: "scripts/push-local-learnings.py",
                 files: [
                   {
                     "path" => "skill/alms-learning-SKILL-v2.1.md",
                     "media_type" => "text/markdown"
                   }
                 ]
               )
             }
           }
         },
         headers: headers_with_auth(author), as: :json

    assert_response :success
    rejected_publish_body = response.parsed_body.dig("result", "publication")
    assert_equal "rejected", rejected_publish_body.dig("version", "status")
    assert_equal "rejected", rejected_publish_body.dig("verification", "status")

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "publisher-version-get-rejected",
           method: "skills/version.get",
           params: {
             skill_id: skill_id,
             version: "1.0.0"
           }
         },
         headers: headers_with_auth(author), as: :json

    assert_response :success
    rejected_version_body = response.parsed_body.dig("result", "version")

    assert_equal "rejected", rejected_version_body["status"]
    assert_equal "rejected", rejected_version_body.dig("verification", "status")
    assert_equal false, rejected_version_body.dig("verification", "checks", "bundled_files_valid")
    assert_equal 1, rejected_version_body.dig("artifact", "file_count")

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "buyer-list-after-rejection",
           method: "skills/list"
         },
         headers: headers_with_auth(buyer), as: :json

    assert_response :success
    listed_ids = response.parsed_body.dig("result", "skills").map { |skill| skill["id"] }
    assert_not_includes listed_ids, skill_id
  end
  private

  def alms_manifest(slug:, version:, entrypoint:, files:)
    {
      "name" => slug,
      "description" => "Default ALMS-connected learning workflow for new agents.",
      "version" => version,
      "runtime" => "client",
      "entrypoint" => entrypoint,
      "input_schema" => { "type" => "object" },
      "output_schema" => { "type" => "object" },
      "files" => files
    }
  end
end
