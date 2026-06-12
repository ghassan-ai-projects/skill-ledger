require "test_helper"

class LibraryServiceTest < ActiveSupport::TestCase
  setup do
    @alice = accounts(:alice)
    @bob = accounts(:bob)
    @charlie = accounts(:charlie)
    @data_analysis = skills(:data_analysis)
    @code_review = skills(:code_review)
  end

  test "returns library with correct structure" do
    service = LibraryService.new(@bob)
    result = service.call

    assert_kind_of Array, result[:favorites]
    assert_kind_of Array, result[:purchased]
    assert_kind_of Array, result[:my_skills]
  end

  test "includes authored skills" do
    service = LibraryService.new(@alice)
    result = service.call

    names = result[:my_skills].map { |s| s["name"] }
    assert_includes names, "Data Analysis"
  end

  test "includes favorited skills" do
    service = LibraryService.new(@bob)
    result = service.call

    names = result[:favorites].map { |s| s["name"] }
    assert_includes names, "Data Analysis"
    assert_includes names, "Code Review"
  end

  test "includes purchased skills" do
    service = LibraryService.new(@bob)
    result = service.call

    names = result[:purchased].map { |s| s["name"] }
    assert_includes names, "Data Analysis"
  end

  test "purchased includes purchase metadata" do
    service = LibraryService.new(@bob)
    result = service.call

    result[:purchased].each do |s|
      assert s.key?("purchased_version")
      assert s.key?("purchase_status")
      assert s.key?("purchased_at")
    end
  end

  test "includes is_favorited flag on all entries" do
    service = LibraryService.new(@bob)
    result = service.call

    %i[favorites purchased my_skills].each do |key|
      result[key].each do |s|
        assert_includes [ true, false ], s["is_favorited"]
      end
    end
  end

  test "returns empty arrays for user with no activity" do
    service = LibraryService.new(@charlie)
    result = service.call

    assert_equal [], result[:favorites]
    assert_equal [], result[:my_skills]
  end
end
