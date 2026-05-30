require "test_helper"

class FavoriteServiceTest < ActiveSupport::TestCase
  setup do
    @alice = accounts(:alice)
    @bob = accounts(:bob)
    @charlie = accounts(:charlie)
    @data_analysis = skills(:data_analysis)
    @code_review = skills(:code_review)
  end

  # ── Create ─────────────────────────────────────────────────────

  test "adds a favorite" do
    service = FavoriteService.new(@charlie)

    assert_difference("Favorite.count", 1) do
      favorite = service.create(skill_id: @data_analysis.id)
      assert_equal @charlie.id, favorite.account_id
      assert_equal @data_analysis.id, favorite.skill_id
    end
  end

  test "raises error for duplicate favorite" do
    service = FavoriteService.new(@bob)

    assert_raises FavoriteService::Error, match: "already in your favorites" do
      service.create(skill_id: @data_analysis.id)
    end
  end

  test "raises error for missing skill" do
    service = FavoriteService.new(@alice)
    assert_raises ActiveRecord::RecordNotFound do
      service.create(skill_id: 99999)
    end
  end

  # ── Destroy ────────────────────────────────────────────────────

  test "removes a favorite" do
    service = FavoriteService.new(@bob)

    assert_difference("Favorite.count", -1) do
      assert service.destroy(skill_id: @data_analysis.id)
    end
  end

  test "raises error when favorite not found" do
    service = FavoriteService.new(@charlie)

    assert_raises FavoriteService::Error, match: "Favorite not found" do
      service.destroy(skill_id: @data_analysis.id)
    end
  end
end
