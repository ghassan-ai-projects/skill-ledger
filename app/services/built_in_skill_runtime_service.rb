class BuiltInSkillRuntimeService
  class Error < StandardError
    attr_reader :code

    def initialize(message, code:)
      @code = code
      super(message)
    end
  end

  DATA_ANALYSIS_SKILL_NAME = "Data Analysis".freeze

  class << self
    def input_schema_for(skill)
      return {} unless supports?(skill)

      {
        type: "object",
        required: [ "numbers" ],
        properties: {
          dataset_name: {
            type: "string",
            description: "Optional dataset label for the result payload"
          },
          numbers: {
            type: "array",
            items: { type: "number" },
            minItems: 1,
            description: "Numeric values to summarize"
          }
        },
        additionalProperties: false
      }
    end

    def supports?(skill)
      skill.name == DATA_ANALYSIS_SKILL_NAME
    end

    def execute(skill, arguments)
      raise Error.new("Skill is not a built-in runtime", code: :unsupported_skill) unless supports?(skill)

      execute_data_analysis(arguments)
    end

    private

    def execute_data_analysis(arguments)
      args = arguments.to_h
      numbers = args["numbers"] || args[:numbers]

      unless numbers.is_a?(Array) && numbers.any?
        raise Error.new("numbers must be a non-empty array", code: :invalid_arguments)
      end

      normalized_numbers = numbers.map do |value|
        Float(value)
      rescue ArgumentError, TypeError
        raise Error.new("numbers must contain only numeric values", code: :invalid_arguments)
      end

      sorted = normalized_numbers.sort
      count = normalized_numbers.length
      sum = normalized_numbers.sum.to_f

      {
        dataset_name: args["dataset_name"] || args[:dataset_name],
        count: count,
        sum: sum,
        min: sorted.first,
        max: sorted.last,
        average: (sum / count).to_f,
        median: median(sorted)
      }
    end

    def median(sorted_numbers)
      middle = sorted_numbers.length / 2

      if sorted_numbers.length.odd?
        sorted_numbers[middle]
      else
        ((sorted_numbers[middle - 1] + sorted_numbers[middle]) / 2.0).to_f
      end
    end
  end
end
