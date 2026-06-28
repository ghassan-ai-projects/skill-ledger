module Api
  module V1
    class SkillsController < BaseController
      def index
        skills = Skill.includes(:author)

        if params[:q].present?
          q = "%#{params[:q]}%"
          skills = skills.where("name LIKE ? OR description LIKE ?", q, q)
        end

        skills = skills.where(author_id: params[:author_id]) if params[:author_id].present?

        sorted = apply_sorting(skills)
        return unless sorted

        result = paginate(sorted)
        paginated_skills = result[:collection]
        meta = result[:meta]

        render json: {
          skills: paginated_skills.map { |s| format_skill(s) },
          meta: meta
        }
      end

      def show
        skill = Skill.includes(:author).find(params[:id])
        render json: format_skill(skill)
      end

      def create
        creation_params = skill_params.merge(author_id: @current_account.id)
        result = SkillCreationService.new(creation_params).call
        render json: result, status: :created
      rescue SkillCreationService::Error => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def create_version
        skill = Skill.find(params[:id])
        result = SkillVersionRegistrationService.new(skill: skill, author: @current_account).call(**version_registration_params)
        render json: result, status: :created
      rescue SkillVersionRegistrationService::AuthorizationError => e
        render json: { error: e.message, details: [] }, status: :forbidden
      rescue SkillVersionRegistrationService::Error => e
        render json: { error: e.message, details: [] }, status: :unprocessable_entity
      end

      def update_listing_status
        skill = Skill.find(params[:id])
        updated_skill = SkillListingStatusService.new(skill: skill, actor: @current_account).call(
          listing_status: listing_status_params[:listing_status]
        )

        render json: format_skill(updated_skill)
      rescue SkillListingStatusService::AuthorizationError => e
        render json: { error: e.message, details: [] }, status: :forbidden
      rescue SkillListingStatusService::Error => e
        render json: { error: e.message, details: [] }, status: :unprocessable_entity
      end

      def version_review
        skill = Skill.find(params[:id])
        skill_version = skill.skill_versions.find(params[:version_id])
        review = skill_version.skill_review

        render json: {
          skill_id: skill.id,
          version: skill_version.version,
          status: review&.status,
          review_type: review&.review_type,
          decision_reason: review&.decision_reason,
          submitted_at: review&.submitted_at,
          decided_at: review&.decided_at
        }
      end

      private

      def skill_params
        params.require(:skill).permit(:name, :description, :price)
      end

      def version_registration_params
        permitted = params.require(:version).permit(
          :version,
          :changelog,
          artifact: [
            :artifact_type,
            { manifest: {} }
          ]
        ).to_h.deep_symbolize_keys

        artifact = permitted[:artifact] || {}
        permitted.merge(artifact: artifact)
      end

      def listing_status_params
        params.require(:skill).permit(:listing_status)
      end

      def format_skill(skill)
        base = skill.as_json(
          only: %i[id slug name description author_id listing_status price created_at updated_at],
          include: { author: { only: %i[id name] } }
        )
        base.merge(
          "latest_verified_version" => skill.skill_versions.where(status: "verified").order(created_at: :desc).limit(1).pick(:version),
          "latest_approved_version" => SkillMarketplaceEligibilityService.approved_version_for(skill)&.version,
          "favorite_count" => skill.favorite_count,
          "is_favorited" => skill.is_favorited(@current_account)
        )
      end
    end
  end
end
