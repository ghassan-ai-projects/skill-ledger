require "test_helper"

class AnalyticsServiceTest < ActiveSupport::TestCase
  setup do
    @alice = accounts(:alice)
    @bob = accounts(:bob)
    @charlie = accounts(:charlie)
    @data_analysis = skills(:data_analysis)
    @code_review = skills(:code_review)
  end

  # ── Show ───────────────────────────────────────────────────────

  test "returns analytics for own account" do
    service = AnalyticsService.new(@alice)
    result = service.show(author_id: @alice.id)

    assert_equal @alice.id, result[:author][:id]
    assert_equal "Alice", result[:author][:name]
    assert result.key?(:total_skills)
    assert result.key?(:total_purchases)
    assert result.key?(:total_revenue)
    assert result.key?(:recent_purchases)
  end

  test "raises forbidden for another account's analytics" do
    service = AnalyticsService.new(@alice)
    assert_raises AnalyticsService::Forbidden do
      service.show(author_id: @bob.id)
    end
  end

  test "raises not found for non-existent author" do
    service = AnalyticsService.new(@alice)
    assert_raises ActiveRecord::RecordNotFound do
      service.show(author_id: 99999)
    end
  end

  test "includes top_skills" do
    service = AnalyticsService.new(@alice)
    result = service.show(author_id: @alice.id)

    assert_kind_of Array, result[:top_skills]
    assert result[:top_skills].all? { |s| s.key?(:purchase_count) }
  end

  test "includes recent_purchases" do
    service = AnalyticsService.new(@alice)
    result = service.show(author_id: @alice.id)

    assert_kind_of Array, result[:recent_purchases]
  end

  test "returns zeros for author with no purchases" do
    service = AnalyticsService.new(@charlie)
    result = service.show(author_id: @charlie.id)

    assert_equal 0, result[:total_skills]
    assert_equal 0, result[:total_purchases]
    assert_equal 0.0, result[:total_revenue]
  end

  # ── Earnings ───────────────────────────────────────────────────

  test "returns earnings data" do
    service = AnalyticsService.new(@alice)
    result = service.earnings(author_id: @alice.id)

    assert_kind_of Array, result[:earnings_over_time]
    assert result.key?(:total_earnings)
    assert result.key?(:average_per_day)
  end

  test "raises forbidden for another author's earnings" do
    service = AnalyticsService.new(@alice)
    assert_raises AnalyticsService::Forbidden do
      service.earnings(author_id: @bob.id)
    end
  end

  test "returns empty data for no earnings" do
    service = AnalyticsService.new(@charlie)
    result = service.earnings(author_id: @charlie.id)

    assert_equal [], result[:earnings_over_time]
    assert_equal 0, result[:total_earnings]
    assert_equal 0.0, result[:average_per_day]
    assert_nil result[:best_skill]
  end
end
