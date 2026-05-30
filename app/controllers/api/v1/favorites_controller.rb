module Api
  module V1
    class FavoritesController < BaseController
      # POST /api/v1/favorites
      def create
        favorite = FavoriteService.new(@current_account).create(skill_id: favorite_params[:skill_id])
        render json: { message: "Skill added to favorites", favorite_id: favorite.id }, status: :created
      rescue FavoriteService::Error => e
        render json: { error: e.message, details: [] }, status: :unprocessable_entity
      end

      # DELETE /api/v1/favorites/:skill_id
      def destroy
        FavoriteService.new(@current_account).destroy(skill_id: params[:id])
        head :no_content
      rescue FavoriteService::Error => e
        render json: { error: e.message, details: [] }, status: :not_found
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
          methods: [ :average_rating, :review_count ]
        ).merge(
          "favorite_count" => skill.favorite_count,
          "is_favorited" => true
        )
      end
    end
  end
end
