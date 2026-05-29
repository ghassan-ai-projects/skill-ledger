module Api
  module V1
    class ReportsController < BaseController
      def index
        render json: {
          total_skills: Skill.count,
          total_executions: Execution.count,
          completed_executions: Execution.where(status: "completed").count,
          failed_executions: Execution.where(status: "failed").count,
          total_slashed: LedgerEntry.where(entry_type: "slash").sum(:amount).to_f,
          total_ledger_balance: Account.sum(:balance).to_f
        }
      end
    end
  end
end
