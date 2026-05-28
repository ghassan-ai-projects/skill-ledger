module Api
  module V1
    class ExecutionsController < ApplicationController
      def index
        executions = Execution.includes(:skill, :buyer).all
        render json: executions.as_json(
          include: {
            skill: { only: %i[id name], methods: [] },
            buyer: { only: %i[id name] }
          }
        )
      end

      def create
        skill = Skill.find(params[:skill_id])
        buyer = Account.find_by(id: params[:buyer_id])
        return render json: { error: "Buyer not found" }, status: :unprocessable_entity unless buyer
        return render json: { error: "Cannot execute your own skill" }, status: :unprocessable_entity if buyer == skill.author
        return render json: { error: "Buyer has insufficient balance" }, status: :unprocessable_entity if buyer.balance < skill.price_per_call

        LedgerTransactionService.new(
          from_account: buyer,
          to_account: skill.author,
          amount: skill.price_per_call,
          entry_type: "skill_execution"
        ).call

        execution = Execution.create!(
          skill: skill,
          buyer: buyer,
          status: "completed",
          timestamp: Time.current
        )

        render json: execution, status: :created
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Skill not found" }, status: :not_found
      rescue LedgerTransactionService::InsufficientBalanceError
        render json: { error: "Buyer has insufficient balance" }, status: :unprocessable_entity
      end

      def fail
        execution = Execution.find(params[:id])
        return render json: { error: "Execution is already failed" }, status: :unprocessable_entity if execution.status == "failed"

        skill = execution.skill
        author = skill.author
        buyer = execution.buyer

        Account.transaction do
          author.update!(balance: author.balance - skill.stake_amount)
          buyer.update!(balance: buyer.balance + skill.price_per_call)
          buyer.update!(balance: buyer.balance + skill.stake_amount)
          author.update!(balance: author.balance - skill.price_per_call)

          LedgerEntry.create!(
            from_account: author,
            to_account: buyer,
            amount: skill.stake_amount,
            entry_type: "slash",
            timestamp: Time.current
          )

          LedgerEntry.create!(
            from_account: author,
            to_account: buyer,
            amount: skill.price_per_call,
            entry_type: "refund",
            timestamp: Time.current
          )

          execution.update!(status: "failed")
        end

        render json: execution, status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Execution not found" }, status: :not_found
      rescue ActiveRecord::RecordInvalid
        render json: { error: "Insufficient balance to process failure" }, status: :unprocessable_entity
      end
    end
  end
end
