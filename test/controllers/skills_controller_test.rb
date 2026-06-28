require "test_helper"

class Api::V1::SkillsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = accounts(:alice)
    @bob = accounts(:bob)
    @data_analysis = skills(:data_analysis)
    @code_review = skills(:code_review)
  end

  # ── Authentication ────────────────────────────────────────────

  test "returns 401 when X-API-Key header is missing" do
    get api_v1_skills_url
    assert_response :unauthorized
    assert_includes response.parsed_body["error"], "Invalid or missing API key"
  end

  test "returns 401 when X-API-Key header is invalid" do
    get api_v1_skills_url, headers: { "X-API-Key" => "invalid_key" }
    assert_response :unauthorized
    assert_includes response.parsed_body["error"], "Invalid or missing API key"
  end

  test "passes authentication with a valid API key" do
    get api_v1_skills_url, headers: headers_with_auth(@alice)
    assert_response :success
  end

  test "authentication updates account last_used_at" do
    @alice.update_column(:last_used_at, nil)

    get api_v1_skills_url, headers: headers_with_auth(@alice)

    assert_response :success
    assert_not_nil @alice.reload.last_used_at
  end

  # ── Index ──────────────────────────────────────────────────────

  test "GET /api/v1/skills returns all skills" do
    get api_v1_skills_url, headers: headers_with_auth(@alice)
    assert_response :success

    body = response.parsed_body
    assert_equal 2, body["skills"].length
    names = body["skills"].map { |s| s["name"] }
    assert_includes names, "Data Analysis"
    assert_includes names, "Code Review"
  end

  test "GET /api/v1/skills includes meta with pagination info" do
    get api_v1_skills_url, headers: headers_with_auth(@alice)
    assert_response :success

    meta = response.parsed_body["meta"]
    assert_equal 1, meta["current_page"]
    assert_equal 1, meta["total_pages"]
    assert_equal 2, meta["total_count"]
    assert_equal 20, meta["per_page"]
  end

  test "GET /api/v1/skills includes author info" do
    get api_v1_skills_url, headers: headers_with_auth(@alice)
    assert_response :success

    skill = response.parsed_body["skills"].find { |s| s["name"] == "Data Analysis" }
    assert_not_nil skill["author"]
    assert_equal @alice.id, skill["author"]["id"]
    assert_equal "Alice", skill["author"]["name"]
  end

  test "GET /api/v1/skills includes version and favorite metadata" do
    get api_v1_skills_url, headers: headers_with_auth(@alice)
    assert_response :success

    skill = response.parsed_body["skills"].find { |s| s["name"] == "Data Analysis" }
    assert skill.key?("latest_verified_version")
    assert skill.key?("latest_approved_version")
    assert skill.key?("favorite_count")
    assert skill.key?("is_favorited")
  end

  test "GET /api/v1/skills returns empty list when no skills exist" do
    # Purchases restrict skill_version deletion, so clear dependent records first.
    Purchase.delete_all
    Skill.destroy_all

    get api_v1_skills_url, headers: headers_with_auth(@alice)
    assert_response :success
    assert_equal [], response.parsed_body["skills"]
    assert_equal 0, response.parsed_body["meta"]["total_count"]
  end

  # ── Search ─────────────────────────────────────────────────────

  test "GET /api/v1/skills?q= filters by name (case-insensitive)" do
    get api_v1_skills_url(q: "data"), headers: headers_with_auth(@alice)
    assert_response :success

    body = response.parsed_body
    assert_equal 1, body["skills"].length
    assert_equal "Data Analysis", body["skills"][0]["name"]
  end

  test "GET /api/v1/skills?q= filters by description" do
    get api_v1_skills_url(q: "generate reports"), headers: headers_with_auth(@alice)
    assert_response :success

    body = response.parsed_body
    assert_equal 1, body["skills"].length
    assert_equal "Data Analysis", body["skills"][0]["name"]
  end

  test "GET /api/v1/skills?q= returns empty when no match" do
    get api_v1_skills_url(q: "zzzzz"), headers: headers_with_auth(@alice)
    assert_response :success
    assert_equal [], response.parsed_body["skills"]
    assert_equal 0, response.parsed_body["meta"]["total_count"]
  end

  # ── Author filter ──────────────────────────────────────────────

  test "GET /api/v1/skills?author_id= filters by author" do
    get api_v1_skills_url(author_id: @alice.id), headers: headers_with_auth(@alice)
    assert_response :success

    body = response.parsed_body
    assert_equal 1, body["skills"].length
    assert_equal @alice.id, body["skills"][0]["author_id"]
  end

  test "GET /api/v1/skills?author_id= returns empty for non-existent author" do
    get api_v1_skills_url(author_id: 99999), headers: headers_with_auth(@alice)
    assert_response :success
    assert_equal [], response.parsed_body["skills"]
  end

  test "GET /api/v1/skills combines q and author_id filters" do
    get api_v1_skills_url(q: "code", author_id: @bob.id), headers: headers_with_auth(@alice)
    assert_response :success

    body = response.parsed_body
    assert_equal 1, body["skills"].length
    assert_equal "Code Review", body["skills"][0]["name"]
  end

  test "GET /api/v1/skills with combined filters returns empty when no match" do
    get api_v1_skills_url(q: "data", author_id: @bob.id), headers: headers_with_auth(@alice)
    assert_response :success
    assert_equal [], response.parsed_body["skills"]
  end

  # ── Sort ───────────────────────────────────────────────────────

  test "GET /api/v1/skills?sort=name&order=asc sorts ascending" do
    get api_v1_skills_url(sort: "name", order: "asc"), headers: headers_with_auth(@alice)
    assert_response :success

    names = response.parsed_body["skills"].map { |s| s["name"] }
    assert_equal [ "Code Review", "Data Analysis" ], names
  end

  test "GET /api/v1/skills?sort=name&order=desc sorts descending" do
    get api_v1_skills_url(sort: "name", order: "desc"), headers: headers_with_auth(@alice)
    assert_response :success

    names = response.parsed_body["skills"].map { |s| s["name"] }
    assert_equal [ "Data Analysis", "Code Review" ], names
  end

  test "GET /api/v1/skills returns 422 for invalid sort column" do
    get api_v1_skills_url(sort: "invalid_column"), headers: headers_with_auth(@alice)
    assert_response :unprocessable_entity
    assert_includes response.parsed_body["error"], "Invalid sort column"
  end

  # ── Pagination ─────────────────────────────────────────────────

  test "GET /api/v1/skills?page=1&per_page=1 returns first page" do
    get api_v1_skills_url(page: 1, per_page: 1), headers: headers_with_auth(@alice)
    assert_response :success

    body = response.parsed_body
    assert_equal 1, body["skills"].length
    assert_equal 1, body["meta"]["current_page"]
    assert_equal 2, body["meta"]["total_pages"]
    assert_equal 2, body["meta"]["total_count"]
    assert_equal 1, body["meta"]["per_page"]
  end

  test "GET /api/v1/skills?page=2&per_page=1 returns second page" do
    get api_v1_skills_url(page: 2, per_page: 1), headers: headers_with_auth(@alice)
    assert_response :success

    body = response.parsed_body
    assert_equal 1, body["skills"].length
    assert_equal 2, body["meta"]["current_page"]
  end

  test "GET /api/v1/skills?page=99 returns empty list beyond total pages" do
    get api_v1_skills_url(page: 99), headers: headers_with_auth(@alice)
    assert_response :success
    assert_equal [], response.parsed_body["skills"]
    assert_equal 99, response.parsed_body["meta"]["current_page"]
  end

  test "GET /api/v1/skills?per_page=100 uses max limit" do
    get api_v1_skills_url(per_page: 100), headers: headers_with_auth(@alice)
    assert_response :success
    assert_equal 2, response.parsed_body["skills"].length
    assert_equal 100, response.parsed_body["meta"]["per_page"]
  end

  test "GET /api/v1/skills?per_page=999 caps at max" do
    get api_v1_skills_url(per_page: 999), headers: headers_with_auth(@alice)
    assert_response :success
    assert_equal 2, response.parsed_body["skills"].length
    assert_equal 100, response.parsed_body["meta"]["per_page"]
  end

  # ── Show ───────────────────────────────────────────────────────

  test "GET /api/v1/skills/:id returns the skill" do
    get api_v1_skill_url(@data_analysis), headers: headers_with_auth(@alice)
    assert_response :success

    body = response.parsed_body
    assert_equal "Data Analysis", body["name"]
    assert_equal @alice.id, body["author_id"]
  end

  test "GET /api/v1/skills/:id includes author info" do
    get api_v1_skill_url(@data_analysis), headers: headers_with_auth(@alice)
    assert_response :success

    body = response.parsed_body
    assert_not_nil body["author"]
    assert_equal "Alice", body["author"]["name"]
  end

  test "GET /api/v1/skills/:id includes version and favorite metadata" do
    get api_v1_skill_url(@data_analysis), headers: headers_with_auth(@alice)
    assert_response :success

    body = response.parsed_body
    assert body.key?("latest_verified_version")
    assert body.key?("latest_approved_version")
    assert body.key?("favorite_count")
    assert body.key?("is_favorited")
    assert_equal false, body["is_favorited"] # Alice did not favorite her own skill
  end

  test "GET /api/v1/skills/:id returns 404 for missing skill" do
    get api_v1_skill_url(id: 99999), headers: headers_with_auth(@alice)
    assert_response :not_found
    assert_includes response.parsed_body["error"], "Couldn't find Skill"
    assert_equal [], response.parsed_body["details"]
  end

  test "GET /api/v1/skills/:id returns consistent error shape on 404" do
    get api_v1_skill_url(id: 99999), headers: headers_with_auth(@alice)
    assert_response :not_found
    assert response.parsed_body.key?("error")
    assert response.parsed_body.key?("details")
  end

  # ── Create ─────────────────────────────────────────────────────

  test "POST /api/v1/skills creates a skill" do
    assert_difference("Skill.count", 1) do
      post api_v1_skills_url, params: {
        skill: {
          name: "Test Skill",
          description: "A test",
          price: 10.00
        }
      }, headers: headers_with_auth(@alice), as: :json
    end
    assert_response :created

    body = response.parsed_body
    assert_equal "Test Skill", body["name"]
    assert_equal @alice.id, body["author_id"]
  end

  test "POST /api/v1/skills ignores a supplied author_id and uses the authenticated account" do
    assert_difference("Skill.count", 1) do
      post api_v1_skills_url, params: {
        skill: {
          name: "Attributed Skill",
          author_id: @bob.id,
          price: 10.00
        }
      }, headers: headers_with_auth(@alice), as: :json
    end
    assert_response :created
    assert_equal @alice.id, response.parsed_body["author_id"]
  end

  test "POST /api/v1/skills returns validation errors for missing name" do
    assert_no_difference("Skill.count") do
      post api_v1_skills_url, params: {
        skill: {
          price: 10.00
        }
      }, headers: headers_with_auth(@alice), as: :json
    end
    assert_response :unprocessable_entity
    assert_includes response.parsed_body["error"], "Name"
  end

  test "POST /api/v1/skills rejects negative price" do
    assert_no_difference("Skill.count") do
      post api_v1_skills_url, params: {
        skill: {
          name: "Negative Price",
          price: -10.00
        }
      }, headers: headers_with_auth(@alice), as: :json
    end
    assert_response :unprocessable_entity
    assert_includes response.parsed_body["error"], "greater than or equal to 0"
  end

  # ── Error shapes ───────────────────────────────────────────────

  test "POST /api/v1/skills returns 400 for missing skill params" do
    assert_no_difference("Skill.count") do
      post api_v1_skills_url, params: {}, headers: headers_with_auth(@alice), as: :json
    end
    assert_response :bad_request
    assert_includes response.parsed_body["error"], "Missing required parameter"
    assert response.parsed_body["details"].any? { |d| d.include?("skill") }
  end
end
