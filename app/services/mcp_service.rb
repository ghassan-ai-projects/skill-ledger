class McpService
  class Error < StandardError
    attr_reader :code

    def initialize(message, code:)
      @code = code
      super(message)
    end
  end

  def initialize(current_account)
    @current_account = current_account
  end

  def handle(request_id:, method:, params: {})
    case method
    when "tools/list"
      success(request_id, tools: tools)
    when "tools/call"
      success(request_id, call_tool(params))
    else
      raise Error.new("Method not found: #{method}", code: -32601)
    end
  end

  private

  def success(request_id, result)
    {
      jsonrpc: "2.0",
      id: request_id,
      result: result
    }
  end

  def tools
    Skill.includes(:author).order(:id).map do |skill|
      {
        name: "skill.execute.#{skill.id}",
        description: skill.description,
        inputSchema: input_schema_for(skill),
        annotations: {
          title: skill.name,
          author: skill.author.name,
          price_per_call: skill.price_per_call.to_f
        }
      }
    end
  end

  def call_tool(params)
    tool_name = params[:name] || params["name"]
    skill_id = parse_skill_id(tool_name)
    skill = Skill.find(skill_id)
    arguments = params[:arguments] || params["arguments"] || {}

    if BuiltInSkillRuntimeService.supports?(skill)
      analysis = BuiltInSkillRuntimeService.execute(skill, arguments)
      execution = ExecutionService.new.create(skill_id: skill_id, buyer_id: @current_account.id)
      execution = ExecutionService.new.complete(execution_id: execution.id, result: analysis)

      return {
        content: [
          {
            type: "text",
            text: "Analysis complete for #{analysis[:dataset_name] || 'dataset'} with #{analysis[:count]} values"
          }
        ],
        execution: execution_payload(execution),
        analysis: analysis
      }
    end

    execution = ExecutionService.new.create(skill_id: skill_id, buyer_id: @current_account.id)

    {
      content: [
        {
          type: "text",
          text: "Execution #{execution.id} created for skill #{execution.skill_id} with status #{execution.status}"
        }
      ],
      execution: execution_payload(execution)
    }
  rescue ActiveRecord::RecordNotFound
    raise Error.new("Unknown tool: #{tool_name}", code: -32602)
  rescue BuiltInSkillRuntimeService::Error => e
    raise Error.new(e.message, code: -32602) if e.code == :invalid_arguments

    raise Error.new(e.message, code: -32000)
  rescue ExecutionService::Error => e
    raise Error.new(e.message, code: -32000)
  end

  def input_schema_for(skill)
    schema = BuiltInSkillRuntimeService.input_schema_for(skill)
    return schema unless schema.empty?

    {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  end

  def execution_payload(execution)
    {
      id: execution.id,
      skill_id: execution.skill_id,
      buyer_id: execution.buyer_id,
      status: execution.status
    }
  end

  def parse_skill_id(tool_name)
    match = /\Askill\.execute\.(\d+)\z/.match(tool_name.to_s)
    raise ActiveRecord::RecordNotFound unless match

    match[1]
  end
end
