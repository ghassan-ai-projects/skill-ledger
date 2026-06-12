require "test_helper"

class AlmsSkillBundlePurchaseE2ETest < ActionDispatch::IntegrationTest
  ALMS_SHARED_FILES = [
    "prompts/README.md",
    "prompts/prompts.md",
    "scripts/alms_mcp.py",
    "scripts/fetch-remote-learnings.py",
    "scripts/push-local-learnings.py"
  ].freeze

  test "author publishes versions and buyer purchases a stable acquired version while newer verified versions appear in discovery" do
    author = accounts(:alice)
    buyer = accounts(:charlie)

    created_skill = create_skill_as(author)
    skill_id = created_skill["id"]
    skill_slug = created_skill["slug"]

    version_one_upload = upload_version_as(
      skill_id: skill_id,
      author: author,
      version: "1.0.0",
      changelog: "Initial ALMS learning workflow release",
      manifest: alms_manifest(
        slug: skill_slug,
        version: "1.0.0",
        entrypoint: "scripts/push-local-learnings.py",
        files: build_alms_file_bundle("skill/alms-learning-SKILL-v2.1.md", *ALMS_SHARED_FILES)
      )
    )

    list_skill_as(skill_id: skill_id, author: author)

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "alms-skills-list-v1",
           method: "skills/list"
         },
         headers: headers_with_auth(buyer), as: :json

    assert_response :success
    v1_list_body = response.parsed_body
    listed_skill = v1_list_body["result"]["skills"].find { |skill| skill["id"] == skill_id }

    assert_not_nil listed_skill
    assert_equal "1.0.0", listed_skill.dig("latest_version", "version")

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "alms-skills-purchase-v1",
           method: "skills/purchase",
           params: {
             skill_id: skill_id,
             version: "1.0.0"
           }
         },
         headers: headers_with_auth(buyer), as: :json

    assert_response :success
    purchase_body = response.parsed_body
    purchase_id = purchase_body.dig("result", "purchase", "id")

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "alms-skills-acquire-v1",
           method: "skills/acquire",
           params: {
             purchase_id: purchase_id
           }
         },
         headers: headers_with_auth(buyer), as: :json

    assert_response :success
    first_acquire_body = response.parsed_body
    first_artifact = first_acquire_body.dig("result", "artifact")
    first_entitlement = first_acquire_body.dig("result", "entitlement")

    assert_equal "1.0.0", first_artifact.dig("manifest", "version")
    assert_equal version_one_upload.dig("artifact", "checksum"), first_artifact["checksum"]
    assert_equal SkillArtifactVerificationService.checksum_for_manifest(first_artifact["manifest"]), first_artifact["checksum"]

    prompt_file_v1 = first_artifact["files"].find { |file| file["path"] == "prompts/prompts.md" }
    assert_includes prompt_file_v1["content"], "## A. Store Prompt"

    version_two_files = build_alms_file_bundle("skill/alms-learning-SKILL-v2.1.md", *ALMS_SHARED_FILES)
    version_two_files.find { |file| file["path"] == "prompts/prompts.md" }["content"] += "\n\n## F. Release Note\n\nSecond published bundle.\n"

    version_two_manifest = alms_manifest(
      slug: skill_slug,
      version: "2.0.0",
      entrypoint: "scripts/push-local-learnings.py",
      files: version_two_files
    )

    version_two_upload = upload_version_as(
      skill_id: skill_id,
      author: author,
      version: "2.0.0",
      changelog: "Adds updated prompt bundle content",
      manifest: version_two_manifest
    )
    assert_equal "verified", version_two_upload.dig("version", "status")
    assert_equal "verified", version_two_upload.dig("verification", "status")

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "alms-skills-list-v2",
           method: "skills/list"
         },
         headers: headers_with_auth(buyer), as: :json

    assert_response :success
    v2_list_body = response.parsed_body
    relisted_skill = v2_list_body["result"]["skills"].find { |skill| skill["id"] == skill_id }

    assert_not_nil relisted_skill
    assert_equal "2.0.0", relisted_skill.dig("latest_version", "version")

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "alms-skills-acquire-v1-again",
           method: "skills/acquire",
           params: {
             purchase_id: purchase_id
           }
         },
         headers: headers_with_auth(buyer), as: :json

    assert_response :success
    second_acquire_body = response.parsed_body
    second_artifact = second_acquire_body.dig("result", "artifact")
    second_entitlement = second_acquire_body.dig("result", "entitlement")

    assert_equal "1.0.0", second_artifact.dig("manifest", "version")
    assert_equal first_artifact["checksum"], second_artifact["checksum"]
    assert_equal first_entitlement["acquired_at"], second_entitlement["acquired_at"]
    refute_includes second_artifact["files"].find { |file| file["path"] == "prompts/prompts.md" }["content"], "Second published bundle."

    get "/api/v1/me/library", headers: headers_with_auth(buyer)

    assert_response :success
    library_body = response.parsed_body
    purchased_skill = library_body["purchased"].find { |skill| skill["id"] == skill_id }

    assert_not_nil purchased_skill
    assert_equal "1.0.0", purchased_skill["purchased_version"]
    assert_equal "paid", purchased_skill["purchase_status"]
    assert_not_nil purchased_skill["acquired_at"]
    assert_equal "2.0.0", purchased_skill["latest_verified_version"]
  end

  test "author cannot list a skill before a version passes verification" do
    author = accounts(:alice)
    created_skill = create_skill_as(author)

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "author-list-without-verified-version",
           method: "skills/listing.set_status",
           params: {
             skill_id: created_skill["id"],
             listing_status: "listed"
           }
         },
         headers: headers_with_auth(author), as: :json

    assert_response :unprocessable_entity
    assert_includes response.parsed_body.dig("error", "message"), "verified version"
  end

  test "rejected version never becomes publicly discoverable" do
    author = accounts(:alice)
    buyer = accounts(:charlie)
    created_skill = create_skill_as(author)

    bad_manifest = alms_manifest(
      slug: created_skill["slug"],
      version: "1.0.0",
      entrypoint: "scripts/push-local-learnings.py",
      files: [
        {
          "path" => "skill/alms-learning-SKILL-v2.1.md",
          "media_type" => "text/markdown"
        }
      ]
    )

    rejected_upload = upload_version_as(
      skill_id: created_skill["id"],
      author: author,
      version: "1.0.0",
      changelog: "Broken bundle upload",
      manifest: bad_manifest
    )

    assert_equal "rejected", rejected_upload.dig("version", "status")
    assert_equal "rejected", rejected_upload.dig("verification", "status")

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "author-list-rejected-version",
           method: "skills/listing.set_status",
           params: {
             skill_id: created_skill["id"],
             listing_status: "listed"
           }
         },
         headers: headers_with_auth(author), as: :json

    assert_response :unprocessable_entity
    assert_includes response.parsed_body.dig("error", "message"), "verified version"

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "alms-skills-list-rejected",
           method: "skills/list"
         },
         headers: headers_with_auth(buyer), as: :json

    assert_response :success
    listed_ids = response.parsed_body.dig("result", "skills").map { |skill| skill["id"] }
    assert_not_includes listed_ids, created_skill["id"]
  end

  test "author cannot buy own listed skill and another buyer cannot acquire my purchase" do
    author = accounts(:alice)
    buyer = accounts(:charlie)
    other_buyer = accounts(:bob)
    created_skill = create_skill_as(author)

    upload_version_as(
      skill_id: created_skill["id"],
      author: author,
      version: "1.0.0",
      changelog: "Initial release",
      manifest: alms_manifest(
        slug: created_skill["slug"],
        version: "1.0.0",
        entrypoint: "scripts/push-local-learnings.py",
        files: build_alms_file_bundle("skill/alms-learning-SKILL-v2.1.md", *ALMS_SHARED_FILES)
      )
    )

    list_skill_as(skill_id: created_skill["id"], author: author)

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "author-self-purchase",
           method: "skills/purchase",
           params: {
             skill_id: created_skill["id"],
             version: "1.0.0"
           }
         },
         headers: headers_with_auth(author), as: :json

    assert_response :unprocessable_entity
    assert_equal(-32000, response.parsed_body.dig("error", "code"))
    assert_includes response.parsed_body.dig("error", "message"), "own skill"

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "buyer-purchase",
           method: "skills/purchase",
           params: {
             skill_id: created_skill["id"],
             version: "1.0.0"
           }
         },
         headers: headers_with_auth(buyer), as: :json

    assert_response :success
    purchase_id = response.parsed_body.dig("result", "purchase", "id")

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "other-buyer-acquire",
           method: "skills/acquire",
           params: {
             purchase_id: purchase_id
           }
         },
         headers: headers_with_auth(other_buyer), as: :json

    assert_response :unprocessable_entity
    assert_equal(-32000, response.parsed_body.dig("error", "code"))
    assert_includes response.parsed_body.dig("error", "message"), "does not belong"
  end

  test "non-author cannot upload a new version or change listing status" do
    author = accounts(:alice)
    intruder = accounts(:bob)
    created_skill = create_skill_as(author)

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "intruder-version-publish",
           method: "skills/version.publish",
           params: {
             skill_id: created_skill["id"],
             version: "1.0.0",
             changelog: "Unauthorized upload attempt",
             artifact: {
               artifact_type: "mcp_tool_manifest",
               manifest: alms_manifest(
                 slug: created_skill["slug"],
                 version: "1.0.0",
                 entrypoint: "scripts/push-local-learnings.py",
                 files: build_alms_file_bundle("skill/alms-learning-SKILL-v2.1.md", *ALMS_SHARED_FILES)
               )
             }
           }
         },
         headers: headers_with_auth(intruder), as: :json

    assert_response :unprocessable_entity
    assert_includes response.parsed_body.dig("error", "message"), "do not own"

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "intruder-listing-set-status",
           method: "skills/listing.set_status",
           params: {
             skill_id: created_skill["id"],
             listing_status: "listed"
           }
         },
         headers: headers_with_auth(intruder), as: :json

    assert_response :unprocessable_entity
    assert_includes response.parsed_body.dig("error", "message"), "do not own"
  end

  test "duplicate version upload is rejected in the real publish flow" do
    author = accounts(:alice)
    created_skill = create_skill_as(author)

    upload_version_as(
      skill_id: created_skill["id"],
      author: author,
      version: "1.0.0",
      changelog: "Initial release",
      manifest: alms_manifest(
        slug: created_skill["slug"],
        version: "1.0.0",
        entrypoint: "scripts/push-local-learnings.py",
        files: build_alms_file_bundle("skill/alms-learning-SKILL-v2.1.md", *ALMS_SHARED_FILES)
      )
    )

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "duplicate-version-publish",
           method: "skills/version.publish",
           params: {
             skill_id: created_skill["id"],
             version: "1.0.0",
             changelog: "Duplicate release",
             artifact: {
               artifact_type: "mcp_tool_manifest",
               manifest: alms_manifest(
                 slug: created_skill["slug"],
                 version: "1.0.0",
                 entrypoint: "scripts/push-local-learnings.py",
                 files: build_alms_file_bundle("skill/alms-learning-SKILL-v2.1.md", *ALMS_SHARED_FILES)
               )
             }
           }
         },
         headers: headers_with_auth(author), as: :json

    assert_response :unprocessable_entity
    assert_includes response.parsed_body.dig("error", "message"), "Version has already been taken"
  end

  test "insufficient-balance buyer cannot purchase a listed verified skill" do
    author = accounts(:alice)
    poor_buyer = accounts(:charlie)
    poor_buyer.update!(balance: 10)
    created_skill = create_skill_as(author)

    upload_version_as(
      skill_id: created_skill["id"],
      author: author,
      version: "1.0.0",
      changelog: "High price release",
      manifest: alms_manifest(
        slug: created_skill["slug"],
        version: "1.0.0",
        entrypoint: "scripts/push-local-learnings.py",
        files: build_alms_file_bundle("skill/alms-learning-SKILL-v2.1.md", *ALMS_SHARED_FILES)
      )
    )
    Skill.find(created_skill["id"]).update!(price: 55)
    list_skill_as(skill_id: created_skill["id"], author: author)

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "insufficient-balance-purchase",
           method: "skills/purchase",
           params: {
             skill_id: created_skill["id"],
             version: "1.0.0"
           }
         },
         headers: headers_with_auth(poor_buyer), as: :json

    assert_response :unprocessable_entity
    assert_equal(-32000, response.parsed_body.dig("error", "code"))
    assert_includes response.parsed_body.dig("error", "message"), "insufficient balance"
  end

  test "suspended skill disappears from discovery and cannot be newly purchased" do
    author = accounts(:alice)
    buyer = accounts(:charlie)
    created_skill = create_skill_as(author)

    upload_version_as(
      skill_id: created_skill["id"],
      author: author,
      version: "1.0.0",
      changelog: "Initial release",
      manifest: alms_manifest(
        slug: created_skill["slug"],
        version: "1.0.0",
        entrypoint: "scripts/push-local-learnings.py",
        files: build_alms_file_bundle("skill/alms-learning-SKILL-v2.1.md", *ALMS_SHARED_FILES)
      )
    )
    list_skill_as(skill_id: created_skill["id"], author: author)

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "suspend-listed-skill",
           method: "skills/listing.set_status",
           params: {
             skill_id: created_skill["id"],
             listing_status: "suspended"
           }
         },
         headers: headers_with_auth(author), as: :json

    assert_response :success
    assert_equal "suspended", response.parsed_body.dig("result", "skill", "listing_status")

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "suspended-list",
           method: "skills/list"
         },
         headers: headers_with_auth(buyer), as: :json

    assert_response :success
    listed_ids = response.parsed_body.dig("result", "skills").map { |skill| skill["id"] }
    assert_not_includes listed_ids, created_skill["id"]

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "suspended-purchase",
           method: "skills/purchase",
           params: {
             skill_id: created_skill["id"],
             version: "1.0.0"
           }
         },
         headers: headers_with_auth(buyer), as: :json

    assert_response :unprocessable_entity
    assert_equal(-32000, response.parsed_body.dig("error", "code"))
    assert_includes response.parsed_body.dig("error", "message"), "not publicly listed"
  end

  test "buyer can purchase v2 after v1 and both purchases acquire their own versioned artifacts" do
    author = accounts(:alice)
    buyer = accounts(:charlie)
    created_skill = create_skill_as(author)

    v1_upload = upload_version_as(
      skill_id: created_skill["id"],
      author: author,
      version: "1.0.0",
      changelog: "Initial release",
      manifest: alms_manifest(
        slug: created_skill["slug"],
        version: "1.0.0",
        entrypoint: "scripts/push-local-learnings.py",
        files: build_alms_file_bundle("skill/alms-learning-SKILL-v2.1.md", *ALMS_SHARED_FILES)
      )
    )
    list_skill_as(skill_id: created_skill["id"], author: author)

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "purchase-v1",
           method: "skills/purchase",
           params: {
             skill_id: created_skill["id"],
             version: "1.0.0"
           }
         },
         headers: headers_with_auth(buyer), as: :json

    assert_response :success
    purchase_v1_id = response.parsed_body.dig("result", "purchase", "id")

    version_two_files = build_alms_file_bundle("skill/alms-learning-SKILL-v2.1.md", *ALMS_SHARED_FILES)
    version_two_files.find { |file| file["path"] == "prompts/prompts.md" }["content"] += "\n\n## F. Release Note\n\nVersion two bundle.\n"

    v2_upload = upload_version_as(
      skill_id: created_skill["id"],
      author: author,
      version: "2.0.0",
      changelog: "Second release",
      manifest: alms_manifest(
        slug: created_skill["slug"],
        version: "2.0.0",
        entrypoint: "scripts/push-local-learnings.py",
        files: version_two_files
      )
    )

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "purchase-v2",
           method: "skills/purchase",
           params: {
             skill_id: created_skill["id"],
             version: "2.0.0"
           }
         },
         headers: headers_with_auth(buyer), as: :json

    assert_response :success
    purchase_v2_id = response.parsed_body.dig("result", "purchase", "id")
    refute_equal purchase_v1_id, purchase_v2_id

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "acquire-v1",
           method: "skills/acquire",
           params: {
             purchase_id: purchase_v1_id
           }
         },
         headers: headers_with_auth(buyer), as: :json

    assert_response :success
    acquired_v1 = response.parsed_body.dig("result", "artifact")

    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "acquire-v2",
           method: "skills/acquire",
           params: {
             purchase_id: purchase_v2_id
           }
         },
         headers: headers_with_auth(buyer), as: :json

    assert_response :success
    acquired_v2 = response.parsed_body.dig("result", "artifact")

    assert_equal "1.0.0", acquired_v1.dig("manifest", "version")
    assert_equal "2.0.0", acquired_v2.dig("manifest", "version")
    assert_equal v1_upload.dig("artifact", "checksum"), acquired_v1["checksum"]
    assert_equal v2_upload.dig("artifact", "checksum"), acquired_v2["checksum"]
    refute_equal acquired_v1["checksum"], acquired_v2["checksum"]
    refute_includes acquired_v1["files"].find { |file| file["path"] == "prompts/prompts.md" }["content"], "Version two bundle."
    assert_includes acquired_v2["files"].find { |file| file["path"] == "prompts/prompts.md" }["content"], "Version two bundle."
    assert_equal 2, buyer.purchases.where(skill_version_id: SkillVersion.where(skill_id: created_skill["id"]).select(:id)).count
  end

  private

  def create_skill_as(author)
    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "author-create-skill-#{SecureRandom.hex(4)}",
           method: "skills/create",
           params: skill_create_payload
         },
         headers: headers_with_auth(author), as: :json

    assert_response :success
    response.parsed_body.dig("result", "skill")
  end

  def upload_version_as(skill_id:, author:, version:, changelog:, manifest:)
    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "author-publish-version-#{version}",
           method: "skills/version.publish",
           params: version_upload_payload(skill_id: skill_id, version: version, changelog: changelog, manifest: manifest)
         },
         headers: headers_with_auth(author), as: :json

    assert_response :success
    response.parsed_body.dig("result", "publication")
  end

  def list_skill_as(skill_id:, author:)
    post "/api/v1/mcp",
         params: {
           jsonrpc: "2.0",
           id: "author-list-skill-#{skill_id}",
           method: "skills/listing.set_status",
           params: {
             skill_id: skill_id,
             listing_status: "listed"
           }
         },
          headers: headers_with_auth(author), as: :json

    assert_response :success
    assert_equal "listed", response.parsed_body.dig("result", "skill", "listing_status")
  end

  def skill_create_payload
    {
      name: "ALMS Default Learning Workflow",
      description: "Default ALMS-connected learning workflow for new agents.",
      price: 55
    }
  end

  def version_upload_payload(skill_id:, version:, changelog:, manifest:)
    {
      skill_id: skill_id,
      version: version,
      changelog: changelog,
      artifact: {
        artifact_type: "mcp_tool_manifest",
        manifest: manifest
      }
    }
  end

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
