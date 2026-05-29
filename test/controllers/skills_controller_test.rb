require "test_helper"

class Api::V1::SkillsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = accounts(:alice)
    @bob = accounts(:bob)
    @charlie = accounts(:charlie)
    @data_analysis = skills(:data_analysis)
    @code_review = skills(:code_review)
  end

  # ── Index ──────────────────────────────────────────────────────

  test "GET /api/v1/skills returns all skills" do
    get api_v1_skills_url
    assert_response :success

    body = response.parsed_body
    assert_equal 2, body.length
    names = body.map { |s| s["name"] }
    assert_includes names, "Data Analysis"
    assert_includes names, "Code Review"
  end

  test "GET /api/v1/skills includes author info" do
    get api_v1_skills_url
    assert_response :success

    skill = response.parsed_body.find { |s| s["name"] == "Data Analysis" }
    assert_not_nil skill["author"]
    assert_equal @alice.id, skill["author"]["id"]
    assert_equal "Alice", skill["author"]["name"]
  end

  # ── Show ───────────────────────────────────────────────────────

  test "GET /api/v1/skills/:id returns the skill" do
    get api_v1_skill_url(@data_analysis)
    assert_response :success

    body = response.parsed_body
    assert_equal "Data Analysis", body["name"]
    assert_equal @alice.id, body["author_id"]
  end

  test "GET /api/v1/skills/:id includes author info" do
    get api_v1_skill_url(@data_analysis)
    assert_response :success

    body = response.parsed_body
    assert_not_nil body["author"]
    assert_equal "Alice", body["author"]["name"]
  end

  test "GET /api/v1/skills/:id returns 404 for missing skill" do
    get api_v1_skill_url(id: 99999)
    assert_response :not_found
    assert_includes response.parsed_body["error"], "Couldn't find Skill"
    assert_equal [], response.parsed_body["details"]
  end

  test "GET /api/v1/skills/:id returns consistent error shape on 404" do
    get api_v1_skill_url(id: 99999)
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
          author_id: @alice.id,
          price_per_call: 10.00,
          stake_amount: 50.00
        }
      }, as: :json
    end
    assert_response :created

    body = response.parsed_body
    assert_equal "Test Skill", body["name"]
    assert_equal @alice.id, body["author_id"]
  end

  test "POST /api/v1/skills returns error when author not found" do
    assert_no_difference("Skill.count") do
      post api_v1_skills_url, params: {
        skill: {
          name: "Orphan Skill",
          author_id: 99999,
          price_per_call: 10.00,
          stake_amount: 50.00
        }
      }, as: :json
    end
    assert_response :unprocessable_entity
    assert_includes response.parsed_body["error"], "Author not found"
  end

  test "POST /api/v1/skills returns error when author has insufficient balance for stake" do
    assert_no_difference("Skill.count") do
      post api_v1_skills_url, params: {
        skill: {
          name: "Unstakeable Skill",
          author_id: @bob.id,
          price_per_call: 10.00,
          stake_amount: 9999.00
        }
      }, as: :json
    end
    assert_response :unprocessable_entity
    assert_includes response.parsed_body["error"], "insufficient balance"
  end

  test "POST /api/v1/skills returns validation errors for missing name" do
    assert_no_difference("Skill.count") do
      post api_v1_skills_url, params: {
        skill: {
          author_id: @alice.id,
          price_per_call: 10.00,
          stake_amount: 50.00
        }
      }, as: :json
    end
    assert_response :unprocessable_entity
    assert_includes response.parsed_body["error"], "Name"
  end

  test "POST /api/v1/skills returns 400 for missing skill params" do
    assert_no_difference("Skill.count") do
      post api_v1_skills_url, params: {}, as: :json
    end
    assert_response :bad_request
    assert_includes response.parsed_body["error"], "Missing required parameter"
    assert response.parsed_body["details"].any? { |d| d.include?("skill") }
  end
end
