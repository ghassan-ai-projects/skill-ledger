require "test_helper"

class AlmsSkillBundlePurchaseE2ETest < ActionDispatch::IntegrationTest
  ALMS_SHARED_FILES = [
    "prompts/README.md",
    "prompts/prompts.md",
    "scripts/alms_mcp.py",
    "scripts/fetch-remote-learnings.py",
    "scripts/push-local-learnings.py"
  ].freeze

  test "buyer can discover imported ALMS skills and acquire a full prompt plus python bundle" do
    alms_agent = create_verified_skill_listing(
      name: "ALMS Agent Learning Lifecycle",
      slug: "alms-agent-learning-lifecycle",
      author: accounts(:alice),
      price: 45,
      description: "Shared ALMS learning lifecycle with prompts and helper Python clients.",
      entrypoint: "scripts/fetch-remote-learnings.py",
      file_bundle: build_alms_file_bundle("skill/SKILL.md", *ALMS_SHARED_FILES)
    )

    learning_skill = create_verified_skill_listing(
      name: "ALMS Default Learning Workflow",
      slug: "alms-default-learning-workflow",
      author: accounts(:alice),
      price: 55,
      description: "Default ALMS-connected learning workflow for new agents.",
      entrypoint: "scripts/push-local-learnings.py",
      file_bundle: build_alms_file_bundle("skill/alms-learning-SKILL-v2.1.md", *ALMS_SHARED_FILES)
    )

    buyer = accounts(:charlie)

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "alms-skills-list-1",
           method: "skills/list"
         },
         headers: headers_with_auth(buyer), as: :json

    assert_response :success
    list_body = response.parsed_body
    listed_slugs = list_body.dig("result", "skills").map { |skill| skill["slug"] }

    assert_includes listed_slugs, alms_agent[:skill].slug
    assert_includes listed_slugs, learning_skill[:skill].slug

    imported_skill = list_body["result"]["skills"].find { |skill| skill["slug"] == learning_skill[:skill].slug }
    assert_not_nil imported_skill
    assert_equal "verified", imported_skill.dig("verification", "status")
    assert_equal "1.0.0", imported_skill.dig("latest_version", "version")

    assert_difference("Purchase.count", 1) do
      assert_difference("LedgerEntry.count", 1) do
        post "/api/v1/mcp",
             params: {
               jsonrpc: "2.0",
               id: "alms-skills-purchase-1",
               method: "skills/purchase",
               params: {
                 skill_id: imported_skill["id"],
                 version: imported_skill.dig("latest_version", "version")
               }
             },
             headers: headers_with_auth(buyer), as: :json
      end
    end

    assert_response :success
    purchase_body = response.parsed_body
    purchase_id = purchase_body.dig("result", "purchase", "id")

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "alms-skills-acquire-1",
           method: "skills/acquire",
           params: {
             purchase_id: purchase_id
           }
         },
         headers: headers_with_auth(buyer), as: :json

    assert_response :success
    acquire_body = response.parsed_body

    artifact = acquire_body.dig("result", "artifact")
    verification = acquire_body.dig("result", "verification")
    entitlement = acquire_body.dig("result", "entitlement")
    files = artifact["files"]

    assert_equal "mcp_tool_manifest", artifact["type"]
    assert_equal learning_skill[:artifact].checksum, artifact["checksum"]
    assert_equal learning_skill[:skill].slug, artifact.dig("manifest", "name")
    assert_equal "scripts/push-local-learnings.py", artifact.dig("manifest", "entrypoint")
    assert_equal "verified", verification["status"]
    assert_equal true, verification["checks"]["bundled_files_valid"]
    assert_equal purchase_id, entitlement["purchase_id"]
    assert_equal buyer.id, entitlement["buyer_id"]

    expected_paths = [
      "skill/alms-learning-SKILL-v2.1.md",
      *ALMS_SHARED_FILES
    ]
    assert_equal expected_paths.sort, files.map { |file| file["path"] }.sort
    assert files.all? { |file| file["content"].present? }

    prompt_file = files.find { |file| file["path"] == "prompts/prompts.md" }
    python_file = files.find { |file| file["path"] == "scripts/alms_mcp.py" }

    assert_includes prompt_file["content"], "## A. Store Prompt"
    assert_includes python_file["content"], "class ALMSMCPClient"
  end
end
