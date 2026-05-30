require "test_helper"

class ReviewServiceTest < ActiveSupport::TestCase
  setup do
    @alice = accounts(:alice)
    @bob = accounts(:bob)
    @charlie = accounts(:charlie)
    @data_analysis = skills(:data_analysis)
  end

  test "creates a review successfully" do
    execution = create_completed_execution(@alice, @charlie)
    service = ReviewService.new(@charlie)

    assert_difference("Review.count", 1) do
      review = service.create(execution_id: execution.id, rating: 5, review_text: "Excellent!")
      assert_equal 5, review.rating
      assert_equal "Excellent!", review.review_text
    end
  end

  test "raises error when not the buyer" do
    execution = create_completed_execution(@alice, @charlie)
    service = ReviewService.new(@bob)

    assert_raises ReviewService::Error, match: "Only the buyer" do
      service.create(execution_id: execution.id, rating: 5)
    end
  end

  test "raises error for non-completed execution" do
    pending_exec = Execution.create!(skill: @data_analysis, buyer: @charlie, status: "pending", timestamp: Time.current)
    service = ReviewService.new(@charlie)

    assert_raises ReviewService::Error, match: "Can only review completed" do
      service.create(execution_id: pending_exec.id, rating: 5)
    end
  end

  test "raises error when author tries to review own skill" do
    execution = create_completed_execution(@alice, @charlie)
    service = ReviewService.new(@alice)

    assert_raises ReviewService::Error, match: "Only the buyer" do
      service.create(execution_id: execution.id, rating: 3)
    end
  end

  test "raises error for duplicate review" do
    execution = create_completed_execution(@alice, @charlie)
    service = ReviewService.new(@charlie)
    service.create(execution_id: execution.id, rating: 4)

    assert_raises ReviewService::Error, match: "already has a review" do
      service.create(execution_id: execution.id, rating: 3)
    end
  end

  test "raises error for invalid rating" do
    execution = create_completed_execution(@alice, @charlie)
    service = ReviewService.new(@charlie)

    assert_raises ReviewService::Error do
      service.create(execution_id: execution.id, rating: 6)
    end
  end

  test "raises error for missing execution" do
    service = ReviewService.new(@alice)
    assert_raises ActiveRecord::RecordNotFound do
      service.create(execution_id: 99999, rating: 5)
    end
  end

  private

  def create_completed_execution(skill_author, buyer)
    skill = Skill.create!(name: "Temp Skill #{Time.current.to_i}", author: skill_author, price_per_call: 1, stake_amount: 1)
    Execution.create!(skill: skill, buyer: buyer, status: "completed", timestamp: Time.current)
  end
end
