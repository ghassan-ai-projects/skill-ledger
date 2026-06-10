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
    latest_purchases = @current_account.purchases
      .includes(skill_version: { skill: :author })
      .group_by { |purchase| purchase.skill_version.skill_id }
      .values
      .map { |purchases| purchases.max_by(&:created_at) }

    latest_purchases.map do |purchase|
      skill = purchase.skill_version.skill

      format_skill(skill, favorited: @current_account.favorited_skills.include?(skill)).merge(
        "purchased_version" => purchase.skill_version.version,
        "purchase_status" => purchase.status,
        "purchased_at" => purchase.created_at,
        "acquired_at" => purchase.acquired_at
      )
    end
  end
  # rubocop:enable Metrics/MethodLength

  def build_my_skills
    @current_account.authored_skills.includes(:author).map { |s|
      format_skill(s, favorited: @current_account.favorited_skills.include?(s))
    }
  end

  def format_skill(skill, favorited:)
    skill.as_json(
      only: %i[id slug name description author_id listing_status price created_at updated_at],
      include: { author: { only: %i[id name] } }
    ).merge(
      "latest_verified_version" => skill.skill_versions.where(status: "verified").order(created_at: :desc).limit(1).pick(:version),
      "favorite_count" => skill.favorite_count,
      "is_favorited" => favorited
    )
  end
end
