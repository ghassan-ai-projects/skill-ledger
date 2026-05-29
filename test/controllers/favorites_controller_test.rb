require "test_helper"

class Api::V1::FavoritesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = accounts(:alice)
    @bob = accounts(:bob)
    @charlie = accounts(:charlie)
    @data_analysis = skills(:data_analysis)
    @code_review = skills(:code_review)
  end

  # ── Create ─────────────────────────────────────────────────────

  test "POST /api/v1/favorites adds a favorite" do
    assert_difference("Favorite.count", 1) do
      post api_v1_favorites_url,
           params: { skill_id: @data_analysis.id },
           headers: headers_with_auth(@charlie), as: :json
    end
    assert_response :created
    assert_includes response.parsed_body["message"], "added to favorites"
  end

  test "POST /api/v1/favorites returns 422 for duplicate favorite" do
    # Bob already has data_analysis favorited via fixture
    assert_no_difference("Favorite.count") do
      post api_v1_favorites_url,
           params: { skill_id: @data_analysis.id },
           headers: headers_with_auth(@bob), as: :json
    end
    assert_response :unprocessable_entity
    assert_includes response.parsed_body["error"], "already in your favorites"
  end

  test "POST /api/v1/favorites returns 404 for missing skill" do
    assert_no_difference("Favorite.count") do
      post api_v1_favorites_url,
           params: { skill_id: 99999 },
           headers: headers_with_auth(@alice), as: :json
    end
    assert_response :not_found
  end

  # ── Destroy ────────────────────────────────────────────────────

  test "DELETE /api/v1/favorites/:id removes a favorite" do
    fav = favorites(:favorite_one)

    assert_difference("Favorite.count", -1) do
      delete api_v1_favorite_url(fav.skill_id),
             headers: headers_with_auth(@bob)
    end
    assert_response :no_content
  end

  test "DELETE /api/v1/favorites/:id returns 404 for non-existent favorite" do
    assert_no_difference("Favorite.count") do
      delete api_v1_favorite_url(id: 99999),
             headers: headers_with_auth(@alice)
    end
    assert_response :not_found
  end

  test "DELETE /api/v1/favorites/:id returns 404 when skill not favorited by user" do
    # Charlie hasn't favorited data_analysis
    assert_no_difference("Favorite.count") do
      delete api_v1_favorite_url(@data_analysis.id),
             headers: headers_with_auth(@charlie)
    end
    assert_response :not_found
  end

  # ── Index ──────────────────────────────────────────────────────

  test "GET /api/v1/favorites returns favorited skills" do
    get api_v1_favorites_url, headers: headers_with_auth(@bob)
    assert_response :success

    body = response.parsed_body
    assert_equal 2, body["favorites"].length
    names = body["favorites"].map { |s| s["name"] }
    assert_includes names, "Data Analysis"
    assert_includes names, "Code Review"
  end

  test "GET /api/v1/favorites returns paginated results" do
    get api_v1_favorites_url(page: 1, per_page: 1), headers: headers_with_auth(@bob)
    assert_response :success

    body = response.parsed_body
    assert_equal 1, body["favorites"].length
    assert_equal 2, body["meta"]["total_count"]
  end

  test "GET /api/v1/favorites returns empty for user with no favorites" do
    get api_v1_favorites_url, headers: headers_with_auth(@alice)
    assert_response :success

    body = response.parsed_body
    assert_equal [], body["favorites"]
    assert_equal 0, body["meta"]["total_count"]
  end

  test "GET /api/v1/favorites includes full skill details" do
    get api_v1_favorites_url, headers: headers_with_auth(@bob)
    assert_response :success

    skill = response.parsed_body["favorites"].first
    assert skill.key?("name")
    assert skill.key?("description")
    assert skill.key?("author")
    assert skill.key?("average_rating")
    assert skill.key?("review_count")
    assert skill.key?("favorite_count")
    assert_equal true, skill["is_favorited"]
  end
end
