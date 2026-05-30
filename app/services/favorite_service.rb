class FavoriteService
  class Error < StandardError; end

  def initialize(current_account)
    @current_account = current_account
  end

  def create(skill_id:)
    skill = Skill.find(skill_id)

    if Favorite.exists?(account: @current_account, skill: skill)
      raise Error, "Skill is already in your favorites"
    end

    favorite = @current_account.favorites.build(skill: skill)

    unless favorite.save
      raise Error, favorite.errors.full_messages.to_sentence
    end

    favorite
  end

  def destroy(skill_id:)
    favorite = @current_account.favorites.find_by(skill_id: skill_id)
    raise Error, "Favorite not found" unless favorite

    favorite.destroy
    true
  end
end
