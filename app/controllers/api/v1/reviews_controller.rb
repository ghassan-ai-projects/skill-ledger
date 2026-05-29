module Api
  module V1
    class ReviewsController < BaseController
      # POST /api/v1/executions/:id/review
      def create
        execution = Execution.find(params[:id])

        # Verify buyer is the current account
        unless execution.buyer_id == @current_account.id
          return render json: { error: "Only the buyer can review this execution", details: [] },
                        status: :forbidden
        end

        # Verify execution is completed
        unless execution.status == "completed"
          return render json: { error: "Can only review completed executions", details: [] },
                        status: :unprocessable_entity
        end

        # Verify not reviewing your own skill
        if execution.skill.author_id == @current_account.id
          return render json: { error: "Cannot review your own skill", details: [] },
                        status: :unprocessable_entity
        end

        # Check duplicate review
        if execution.review.present?
          return render json: { error: "Execution already has a review", details: [] },
                        status: :unprocessable_entity
        end

        review = execution.build_review(
          rating: review_params[:rating],
          review_text: review_params[:review_text]
        )

        if review.save
          render json: format_review(review), status: :created
        else
          render json: { error: review.errors.full_messages.to_sentence, details: review.errors.full_messages },
                 status: :unprocessable_entity
        end
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
