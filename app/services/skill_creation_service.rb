class SkillCreationService
  class Error < StandardError; end

  def initialize(params)
    @params = params
  end

  def call
    author = Account.find_by(id: @params[:author_id])
    raise Error, "Author not found" unless author

    if author.balance < @params[:stake_amount].to_d
      raise Error, "Author has insufficient balance for stake"
    end

    skill = Skill.new(@params)
    unless skill.save
      raise Error, skill.errors.full_messages.to_sentence
    end

    skill.as_json(include: { author: { only: %i[id name] } })
  end
end
