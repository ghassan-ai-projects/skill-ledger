module Api
  module V1
    class ExecutionsController < BaseController
      def index
        executions = Execution.includes(:skill, :buyer)
        executions = executions.where(skill_id: params[:skill_id]) if params[:skill_id].present?

        result = paginate(executions)
        paginated = result[:collection]
        meta = result[:meta]

        render json: {
          executions: paginated.as_json(
            include: {
              skill: { only: %i[id name], methods: [] },
              buyer: { only: %i[id name] }
            }
          ),
          meta: meta
        }
      end

      def create
        execution = ExecutionService.new.create(
          skill_id: params[:skill_id],
          buyer_id: @current_account.id
        )
        render json: execution, status: :created
      rescue ExecutionService::Error, ActiveRecord::RecordNotFound => e
        status_code = e.is_a?(ActiveRecord::RecordNotFound) ? :not_found : :unprocessable_entity
        render json: { error: e.message, details: [] }, status: status_code
      end

      def complete
        execution = Execution.find(params[:id])
        return render_forbidden unless execution.skill.author_id == @current_account.id

        execution = ExecutionService.new.complete(execution_id: execution.id)
        render json: execution, status: :ok
      rescue ExecutionService::Error, ActiveRecord::RecordNotFound => e
        status_code = e.is_a?(ActiveRecord::RecordNotFound) ? :not_found : :unprocessable_entity
        render json: { error: e.message, details: [] }, status: status_code
      end

      def fail
        execution = Execution.find(params[:id])
        return render_forbidden unless execution.skill.author_id == @current_account.id

        execution = ExecutionService.new.fail(execution_id: execution.id)
        render json: execution, status: :ok
      rescue ExecutionService::Error, ActiveRecord::RecordNotFound => e
        status_code = e.is_a?(ActiveRecord::RecordNotFound) ? :not_found : :unprocessable_entity
        render json: { error: e.message, details: [] }, status: status_code
      end

      private

      def render_forbidden
        render json: { error: "Only the skill author can perform this action", details: [] }, status: :forbidden
      end
    end
  end
end
