module Api
  module V1
    class LibraryController < BaseController
      # GET /api/v1/me/library
      def index
        # Favorited skills
        favorites = @current_account.favorited_skills.includes(:author).map { |s|
          format_skill(s, favorited: true)
        }

        # Purchased skills (skills the account has executed)
        purchased_skill_ids = @current_account.purchased_executions
          .select(:skill_id)
          .distinct
          .pluck(:skill_id)

        purchased = Skill.includes(:author).where(id: purchased_skill_ids).map { |s|
          last_exec = @current_account.purchased_executions
            .where(skill_id: s.id)
            .order(timestamp: :desc)
            .first

          format_skill(s, favorited: @current_account.favorited_skills.include?(s)).merge(
            "last_execution_timestamp" => last_exec&.timestamp
          )
        }

        # Skills authored by this account
        my_skills = @current_account.authored_skills.includes(:author).map { |s|
          format_skill(s, favorited: @current_account.favorited_skills.include?(s))
        }

        render json: {
          favorites: favorites,
          purchased: purchased,
          my_skills: my_skills
        }
      end

      private

      def format_skill(skill, favorited: false)
        skill.as_json(
          only: %i[id name description author_id stake_amount price_per_call created_at updated_at],
          include: { author: { only: %i[id name] } },
          methods: [:average_rating, :review_count]
        ).merge(
          "favorite_count" => skill.favorite_count,
          "is_favorited" => favorited
        )
      end
    end
  end
end
