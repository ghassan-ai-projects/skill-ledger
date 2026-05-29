require "test_helper"

class Api::V1::LibraryControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = accounts(:alice)
    @bob = accounts(:bob)
    @charlie = accounts(:charlie)
    @data_analysis = skills(:data_analysis)
    @code_review = skills(:code_review)
  end

  test "GET /api/v1/me/library returns library data" do
    get api_v1_me_library_url, headers: headers_with_auth(@alice)
    assert_response :success

    body = response.parsed_body
    assert body.key?("favorites")
    assert body.key?("purchased")
    assert body.key?("my_skills")
  end

  test "GET /api/v1/me/library includes authored skills" do
    get api_v1_me_library_url, headers: headers_with_auth(@alice)
    assert_response :success

    my_skills = response.parsed_body["my_skills"]
    assert_equal 1, my_skills.length
    assert_equal "Data Analysis", my_skills[0]["name"]
  end

  test "GET /api/v1/me/library includes favorited skills" do
    get api_v1_me_library_url, headers: headers_with_auth(@bob)
    assert_response :success

    favorites = response.parsed_body["favorites"]
    assert_equal 2, favorites.length
  end

  test "GET /api/v1/me/library includes purchased skills" do
    # Bob bought data_analysis (execution_one)
    get api_v1_me_library_url, headers: headers_with_auth(@bob)
    assert_response :success

    purchased = response.parsed_body["purchased"]
    assert purchased.any? { |s| s["name"] == "Data Analysis" }
  end

  test "GET /api/v1/me/library purchased includes last_execution_timestamp" do
    get api_v1_me_library_url, headers: headers_with_auth(@bob)
    assert_response :success

    purchased = response.parsed_body["purchased"]
    skill = purchased.find { |s| s["name"] == "Data Analysis" }
    assert_not_nil skill["last_execution_timestamp"]
  end

  test "GET /api/v1/me/library returns correct structure for user with purchases" do
    get api_v1_me_library_url, headers: headers_with_auth(@charlie)
    assert_response :success

    body = response.parsed_body
    assert_instance_of Array, body["favorites"]
    assert_instance_of Array, body["purchased"]
    assert_instance_of Array, body["my_skills"]
    # Charlie purchased code_review via execution_two fixture
    assert body["purchased"].any? { |s| s["name"] == "Code Review" }
  end

  test "GET /api/v1/me/library skills include favorite_count and is_favorited" do
    get api_v1_me_library_url, headers: headers_with_auth(@bob)
    assert_response :success

    body = response.parsed_body
    body["favorites"].each do |s|
      assert s.key?("favorite_count")
      assert s.key?("is_favorited")
    end
  end
end
