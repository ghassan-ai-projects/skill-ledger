class LibraryService
  def initialize(current_account)
    @current_account = current_account
  end

  # rubocop:disable Metrics/MethodLength
  def call
    {
      favorites: build_favorites,
      purchased: build_purchased,
      my_skills: build_my_skills
    }
  end
  # rubocop:enable Metrics/MethodLength

  private

  def build_favorites
    @current_account.favorited_skills.includes(:author).map { |s|
      format_skill(s, favorited: true)
    }
  end

  # rubocop:disable Metrics/MethodLength
  def build_purchased
    purchased_skill_ids = @current_account.purchased_executions
      .select(:skill_id)
      .distinct
      .pluck(:skill_id)

    Skill.includes(:author).where(id: purchased_skill_ids).map { |s|
      last_exec = @current_account.purchased_executions
        .where(skill_id: s.id)
        .order(timestamp: :desc)
        .first

      format_skill(s, favorited: @current_account.favorited_skills.include?(s)).merge(
        "last_execution_timestamp" => last_exec&.timestamp
      )
    }
  end
  # rubocop:enable Metrics/MethodLength

  def build_my_skills
    @current_account.authored_skills.includes(:author).map { |s|
      format_skill(s, favorited: @current_account.favorited_skills.include?(s))
    }
  end

  def format_skill(skill, favorited:)
    skill.as_json(
      only: %i[id name description author_id stake_amount price_per_call created_at updated_at],
      include: { author: { only: %i[id name] } },
      methods: [ :average_rating, :review_count ]
    ).merge(
      "favorite_count" => skill.favorite_count,
      "is_favorited" => favorited
    )
  end
end
