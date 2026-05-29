module Api
  module V1
    class FavoritesController < BaseController
      # POST /api/v1/favorites
      def create
        skill = Skill.find(favorite_params[:skill_id])

        if Favorite.exists?(account: @current_account, skill: skill)
          return render json: { error: "Skill is already in your favorites", details: [] },
                        status: :unprocessable_entity
        end

        favorite = @current_account.favorites.build(skill: skill)

        if favorite.save
          render json: { message: "Skill added to favorites", favorite_id: favorite.id }, status: :created
        else
          render json: { error: favorite.errors.full_messages.to_sentence, details: favorite.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/favorites/:skill_id
      def destroy
        favorite = @current_account.favorites.find_by(skill_id: params[:id])

        unless favorite
          return render json: { error: "Favorite not found", details: [] }, status: :not_found
        end

        favorite.destroy
        head :no_content
      end

      # GET /api/v1/favorites
      def index
        skills = @current_account.favorited_skills.includes(:author)

        result = paginate(skills)
        paginated = result[:collection]
        meta = result[:meta]

        render json: {
          favorites: paginated.map { |s| format_skill(s) },
          meta: meta
        }
      end

      private

      def favorite_params
        params.permit(:skill_id)
      end

      def format_skill(skill)
        skill.as_json(
          only: %i[id name description author_id stake_amount price_per_call created_at updated_at],
          include: { author: { only: %i[id name] } },
          methods: [:average_rating, :review_count]
        ).merge(
          "favorite_count" => skill.favorite_count,
          "is_favorited" => true
        )
      end
    end
  end
end
