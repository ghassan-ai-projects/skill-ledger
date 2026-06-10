require "test_helper"

class BuiltInSkillRuntimeServiceTest < ActiveSupport::TestCase
  setup do
    @data_analysis = skills(:data_analysis)
    @code_review = skills(:code_review)
  end

  test "builds data analysis schema for data analysis skill" do
    schema = BuiltInSkillRuntimeService.input_schema_for(@data_analysis)

    assert_equal "object", schema[:type]
    assert_equal [ "numbers" ], schema[:required]
    assert_equal "array", schema[:properties][:numbers][:type]
  end

  test "returns empty schema for non built-in skills" do
    schema = BuiltInSkillRuntimeService.input_schema_for(@code_review)

    assert_equal({}, schema)
  end

  test "executes data analysis and returns deterministic statistics" do
    result = BuiltInSkillRuntimeService.execute(
      @data_analysis,
      { "dataset_name" => "q1_sales", "numbers" => [ 10, 20, 30, 40 ] }
    )

    assert_equal "q1_sales", result[:dataset_name]
    assert_equal 4, result[:count]
    assert_equal 100.0, result[:sum]
    assert_equal 10.0, result[:min]
    assert_equal 40.0, result[:max]
    assert_equal 25.0, result[:average]
    assert_equal 25.0, result[:median]
  end

  test "rejects missing numbers for data analysis" do
    error = assert_raises(BuiltInSkillRuntimeService::Error) do
      BuiltInSkillRuntimeService.execute(@data_analysis, {})
    end

    assert_equal :invalid_arguments, error.code
  end
end
