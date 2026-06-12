module Api
  module V1
    class ReportsController < BaseController
      def index
        render json: {
          total_skills: Skill.count,
          listed_skills: Skill.where(listing_status: "listed").count,
          verified_skill_versions: SkillVersion.where(status: "verified").count,
          total_purchases: Purchase.count,
          total_revenue: Purchase.sum(:amount).to_f,
          total_ledger_balance: Account.sum(:balance).to_f
        }
      end
    end
  end
end
