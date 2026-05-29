module Api
  module V1
    class SkillsController < BaseController
      def index
        skills = Skill.includes(:author)

        # Search by name or description
        if params[:q].present?
          q = "%#{params[:q]}%"
          skills = skills.where("name LIKE ? OR description LIKE ?", q, q)
        end

        # Filter by author
        skills = skills.where(author_id: params[:author_id]) if params[:author_id].present?

        # Sort
        sorted = apply_sorting(skills)
        return unless sorted

        # Paginate
        result = paginate(sorted)
        paginated_skills = result[:collection]
        meta = result[:meta]

        render json: {
          skills: paginated_skills.as_json(
            include: { author: { only: %i[id name] } },
            methods: [:average_rating, :review_count]
          ),
          meta: meta
        }
      end

      def show
        skill = Skill.includes(:author).find(params[:id])
        render json: skill.as_json(
          include: { author: { only: %i[id name] } },
          methods: [:average_rating, :review_count]
        )
      end

      def create
        author = Account.find_by(id: skill_params[:author_id])
        return render json: { error: "Author not found" }, status: :unprocessable_entity unless author

        if author.balance < skill_params[:stake_amount].to_d
          return render json: { error: "Author has insufficient balance for stake" }, status: :unprocessable_entity
        end

        skill = Skill.new(skill_params)
        if skill.save
          render json: skill.as_json(include: { author: { only: %i[id name] } }), status: :created
        else
          render json: { error: skill.errors.full_messages.to_sentence }, status: :unprocessable_entity
        end
      end

      private

      def skill_params
        params.require(:skill).permit(:name, :description, :author_id, :price_per_call, :stake_amount)
      end
    end
  end
end
