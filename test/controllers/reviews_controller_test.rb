require "test_helper"

class Api::V1::ReviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = accounts(:alice)
    @bob = accounts(:bob)
    @charlie = accounts(:charlie)
    @data_analysis = skills(:data_analysis)
    @code_review = skills(:code_review)
    @execution_one = executions(:execution_one)   # Alice skill, Bob buyer, completed
    @execution_two = executions(:execution_two)   # Bob skill, Charlie buyer, completed
    @review_one = reviews(:review_one)
    @review_two = reviews(:review_two)
  end

  # ── Create ─────────────────────────────────────────────────────

  test "POST /api/v1/executions/:id/review creates a review" do
    execution = create_completed_execution(@alice, @charlie)

    assert_difference("Review.count", 1) do
      post review_api_v1_execution_url(execution),
           params: { rating: 5, review_text: "Excellent!" },
           headers: headers_with_auth(@charlie), as: :json
    end
    assert_response :created

    body = response.parsed_body
    assert_equal 5, body["rating"]
    assert_equal "Excellent!", body["review_text"]
    assert_equal @charlie.name, body["buyer_name"]
  end

  test "POST /api/v1/executions/:id/review returns 403 when not the buyer" do
    execution = create_completed_execution(@alice, @charlie)

    assert_no_difference("Review.count") do
      post review_api_v1_execution_url(execution),
           params: { rating: 5 },
           headers: headers_with_auth(@bob), as: :json
    end
    assert_response :forbidden
    assert_includes response.parsed_body["error"], "Only the buyer"
  end

  test "POST /api/v1/executions/:id/review returns 422 for non-completed execution" do
    pending_exec = Execution.create!(skill: @data_analysis, buyer: @charlie, status: "pending", timestamp: Time.current)

    assert_no_difference("Review.count") do
      post review_api_v1_execution_url(pending_exec),
           params: { rating: 5 },
           headers: headers_with_auth(@charlie), as: :json
    end
    assert_response :unprocessable_entity
    assert_includes response.parsed_body["error"], "Can only review completed"
  end

  test "POST /api/v1/executions/:id/review returns 403 when author tries to review (not the buyer)" do
    # execution_one: Alice (author), Bob (buyer). Alice tries to review.
    assert_no_difference("Review.count") do
      post review_api_v1_execution_url(@execution_one),
           params: { rating: 5 },
           headers: headers_with_auth(@alice), as: :json
    end
    assert_response :forbidden
    assert_includes response.parsed_body["error"], "Only the buyer"
  end

  test "POST /api/v1/executions/:id/review returns 422 for duplicate review" do
    # execution_one already has review_one (Bob already reviewed)
    assert_no_difference("Review.count") do
      post review_api_v1_execution_url(@execution_one),
           params: { rating: 3 },
           headers: headers_with_auth(@bob), as: :json
    end
    assert_response :unprocessable_entity
    assert_includes response.parsed_body["error"], "already has a review"
  end

  test "POST /api/v1/executions/:id/review returns 422 for invalid rating" do
    execution = create_completed_execution(@alice, @charlie)

    assert_no_difference("Review.count") do
      post review_api_v1_execution_url(execution),
           params: { rating: 6 },
           headers: headers_with_auth(@charlie), as: :json
    end
    assert_response :unprocessable_entity
  end

  test "POST /api/v1/executions/:id/review returns 404 for missing execution" do
    assert_no_difference("Review.count") do
      post review_api_v1_execution_url(id: 99999),
           params: { rating: 5 },
           headers: headers_with_auth(@alice), as: :json
    end
    assert_response :not_found
  end

  # ── Index ──────────────────────────────────────────────────────

  test "GET /api/v1/skills/:id/reviews returns reviews for a skill" do
    get reviews_api_v1_skill_url(@data_analysis), headers: headers_with_auth(@alice)
    assert_response :success

    body = response.parsed_body
    assert_equal 1, body["reviews"].length
    assert_equal 4, body["reviews"][0]["rating"]
    assert_equal "Bob", body["reviews"][0]["buyer_name"]
  end

  test "GET /api/v1/skills/:id/reviews returns newest first" do
    get reviews_api_v1_skill_url(@data_analysis), headers: headers_with_auth(@alice)
    assert_response :success
    assert_equal 1, response.parsed_body["reviews"].length
  end

  test "GET /api/v1/skills/:id/reviews returns empty for skill with no reviews" do
    new_skill = Skill.create!(name: "No Reviews", author: @alice, price_per_call: 10, stake_amount: 10)

    get reviews_api_v1_skill_url(new_skill), headers: headers_with_auth(@alice)
    assert_response :success
    assert_equal [], response.parsed_body["reviews"]
    assert_equal 0, response.parsed_body["meta"]["total_count"]
  end

  test "GET /api/v1/skills/:id/reviews returns 404 for missing skill" do
    get reviews_api_v1_skill_url(id: 99999), headers: headers_with_auth(@alice)
    assert_response :not_found
  end

  test "GET /api/v1/skills/:id/reviews includes pagination meta" do
    get reviews_api_v1_skill_url(@data_analysis), headers: headers_with_auth(@alice)
    assert_response :success

    meta = response.parsed_body["meta"]
    assert meta.key?("current_page")
    assert meta.key?("total_pages")
    assert meta.key?("total_count")
  end

  private

  def create_completed_execution(skill_author, buyer)
    skill = Skill.create!(name: "Temp Skill #{Time.current.to_i}", author: skill_author, price_per_call: 1, stake_amount: 1)
    Execution.create!(skill: skill, buyer: buyer, status: "completed", timestamp: Time.current)
  end
end
