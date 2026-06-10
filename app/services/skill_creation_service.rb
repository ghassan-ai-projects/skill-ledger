class SkillCreationService
  class Error < StandardError; end

  def initialize(params)
    @params = params
  end

  def call
    author = Account.find_by(id: @params[:author_id])
    raise Error, "Author not found" unless author

    skill = Skill.new(@params)

    raise Error, skill.errors.full_messages.to_sentence unless skill.save

    skill.as_json(include: { author: { only: %i[id name] } })
  end
end
