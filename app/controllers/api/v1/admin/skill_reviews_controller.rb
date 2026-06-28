module Api
  module V1
    module Admin
      class SkillReviewsController < BaseController
        def index
          scope = SkillReview.includes(skill_version: :skill)
          scope = scope.where(status: params[:status]) if params[:status].present?

          render json: { skill_reviews: scope.order(created_at: :desc).map { |review| format_review(review) } }
        end

        def show
          review = SkillReview.includes(:skill_review_events, skill_version: :skill).find(params[:id])
          render json: format_review(review).merge(events: review.skill_review_events.map { |event| format_event(event) })
        end

        def approve
          decide("approve")
        end

        def reject
          decide("reject")
        end

        def revoke
          decide("revoke")
        end

        private

        def decide(decision)
          review = SkillReview.find(params[:id])
          updated = SkillApprovalService.new(skill_review: review, reviewer_account: @current_account).call(
            decision: decision,
            reason: params[:reason]
          )

          render json: format_review(updated)
        rescue SkillApprovalService::AuthorizationError => e
          render json: { error: e.message, details: [] }, status: :forbidden
        rescue SkillApprovalService::Error => e
          render json: { error: e.message, details: [] }, status: :unprocessable_entity
        end

        def format_event(event)
          {
            id: event.id,
            event_type: event.event_type,
            from_status: event.from_status,
            to_status: event.to_status,
            actor_account_id: event.actor_account_id,
            reason: event.reason,
            created_at: event.created_at
          }
        end

        def format_review(review)
          {
            id: review.id,
            status: review.status,
            review_type: review.review_type,
            policy_checks: review.policy_checks,
            decision_reason: review.decision_reason,
            reviewer_account_id: review.reviewer_account_id,
            submitted_at: review.submitted_at,
            decided_at: review.decided_at,
            skill_version: {
              id: review.skill_version.id,
              skill_id: review.skill_version.skill_id,
              version: review.skill_version.version,
              status: review.skill_version.status
            }
          }
        end
      end
    end
  end
end
