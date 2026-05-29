module Api
  module V1
    class AnalyticsController < BaseController
      # GET /api/v1/authors/:id/analytics?period=all
      def show
        author = Account.find(params[:id])

        # Only the author can view their own analytics
        unless author.id == @current_account.id
          return render json: { error: "You can only access your own analytics", details: [] },
                        status: :forbidden
        end

        period = parse_period(params[:period])

        skills = author.authored_skills
        executions = Execution.where(skill_id: skills.select(:id))
        period_executions = executions.where(timestamp: period) if period

        render json: {
          author: { id: author.id, name: author.name },
          total_skills: skills.count,
          total_executions: executions.count,
          total_earnings: calculate_earnings(author, period).to_f,
          total_slashed: calculate_slashed(author, period).to_f,
          average_rating: calculate_avg_rating(author),
          execution_breakdown: execution_breakdown(period_executions || executions),
          top_skills: top_skills(author, period),
          recent_executions: recent_executions(author, period)
        }
      end

      # GET /api/v1/authors/:id/earnings?period=all
      def earnings
        author = Account.find(params[:id])

        # Only the author can view their own earnings
        unless author.id == @current_account.id
          return render json: { error: "You can only access your own analytics", details: [] },
                        status: :forbidden
        end

        period = parse_period(params[:period])

        completed_execs = Execution.where(skill_id: author.authored_skills.select(:id), status: "completed")
        period_execs = period ? completed_execs.where(timestamp: period) : completed_execs

        daily_data = period_execs
          .group_by { |e| e.timestamp.to_date }
          .map { |date, execs|
            skill = execs.first.skill
            {
              date: date.to_s,
              amount: (execs.size * skill.price_per_call.to_f).round(2),
              execution_count: execs.size
            }
          }
          .sort_by { |d| d[:date] }

        total = daily_data.sum { |d| d[:amount] }
        avg = daily_data.size > 0 ? (total / daily_data.size).round(2) : 0.0

        # Best skill by revenue
        skill_revenue = period_execs
          .group_by { |e| e.skill }
          .map { |skill, execs| { name: skill.name, revenue: (execs.size * skill.price_per_call.to_f).round(2) } }
          .max_by { |s| s[:revenue] }

        render json: {
          earnings_over_time: daily_data,
          total_earnings: total,
          average_per_day: avg,
          best_skill: skill_revenue || nil
        }
      end

      private

      def parse_period(period_str)
        case period_str
        when "last_7_days"
          7.days.ago.beginning_of_day..Time.current
        when "last_30_days"
          30.days.ago.beginning_of_day..Time.current
        when "last_90_days"
          90.days.ago.beginning_of_day..Time.current
        when "this_year"
          Time.current.beginning_of_year..Time.current
        else
          nil # "all" or nil returns everything
        end
      end

      def calculate_earnings(author, period)
        executions = Execution.joins(:skill)
          .where(skills: { author_id: author.id }, status: "completed")
        executions = executions.where(timestamp: period) if period
        executions.sum("skills.price_per_call").to_f
      end

      def calculate_slashed(author, period)
        entries = LedgerEntry.where(from_account: author, entry_type: "slash")
        entries = entries.where(timestamp: period) if period
        entries.sum(:amount).to_f
      end

      def calculate_avg_rating(author)
        skills = author.authored_skills
        reviews = Review.joins(:execution).where(executions: { skill_id: skills.select(:id) })
        reviews.average(:rating)&.to_f
      end

      def execution_breakdown(executions)
        {
          completed: executions.where(status: "completed").count,
          failed: executions.where(status: "failed").count,
          pending: executions.where(status: "pending").count
        }
      end

      def top_skills(author, period)
        skills = author.authored_skills.includes(:executions, :reviews)

        skills.map { |skill|
          execs = period ? skill.executions.where(timestamp: period) : skill.executions
          completed_execs = execs.where(status: "completed")
          {
            id: skill.id,
            name: skill.name,
            execution_count: execs.count,
            total_revenue: (completed_execs.count * skill.price_per_call.to_f).round(2),
            average_rating: skill.average_rating
          }
        }
          .sort_by { |s| -s[:execution_count] }
          .first(5)
      end

      def recent_executions(author, period)
        execs = Execution.includes(:skill, :buyer)
          .where(skill_id: author.authored_skills.select(:id))
        execs = execs.where(timestamp: period) if period
        execs.order(timestamp: :desc).limit(10).map { |e|
          {
            id: e.id,
            skill_name: e.skill.name,
            buyer_name: e.buyer.name,
            status: e.status,
            amount: e.status == "completed" ? e.skill.price_per_call.to_f : 0.0,
            timestamp: e.timestamp
          }
        }
      end
    end
  end
end
