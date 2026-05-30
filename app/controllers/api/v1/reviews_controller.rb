module Api
  module V1
    class ReviewsController < BaseController
      # POST /api/v1/executions/:id/review
      def create
        review = ReviewService.new(@current_account).create(
          execution_id: params[:id],
          rating: review_params[:rating],
          review_text: review_params[:review_text]
        )
        render json: format_review(review), status: :created
      rescue ReviewService::Error => e
        status = e.message.include?("Only the buyer") ? :forbidden : :unprocessable_entity
        render json: { error: e.message, details: [] }, status: status
      end

      # GET /api/v1/skills/:id/reviews
      def index
        skill = Skill.find(params[:id])
        reviews = Review.joins(:execution)
                        .where(executions: { skill_id: skill.id })
                        .includes(execution: :buyer)
                        .order(created_at: :desc)

        result = paginate(reviews)
        paginated = result[:collection]
        meta = result[:meta]

        render json: {
          reviews: paginated.map { |r| format_review(r) },
          meta: meta
        }
      end

      private

      def review_params
        params.permit(:rating, :review_text)
      end

      def format_review(review)
        {
          id: review.id,
          rating: review.rating,
          review_text: review.review_text,
          buyer_name: review.execution.buyer.name,
          created_at: review.created_at
        }
      end
    end
  end
end
