class SkillCreationService
  class Error < StandardError; end

  def initialize(params)
    @params = params
  end

  def call
    author = Account.find_by(id: @params[:author_id])
    raise Error, "Author not found" unless author

    stake = @params[:stake_amount].to_d
    if author.balance < stake
      raise Error, "Author has insufficient balance for stake"
    end

    skill = nil
    Account.transaction do
      author.update!(
        balance: author.balance - stake,
        locked_stake: author.locked_stake + stake
      )
      skill = Skill.new(@params)
      unless skill.save
        raise ActiveRecord::Rollback
      end
    end

    raise Error, skill.errors.full_messages.to_sentence unless skill&.persisted?

    skill.as_json(include: { author: { only: %i[id name] } })
  end
end
