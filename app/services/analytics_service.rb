class AnalyticsService
  def initialize(current_account)
    @current_account = current_account
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def show(author_id:, period: nil)
    author = Account.find(author_id)

    unless author.id == @current_account.id
      raise AnalyticsService::Forbidden, "You can only access your own analytics"
    end

    period_range = parse_period(period)

    skills = author.authored_skills
    executions = Execution.where(skill_id: skills.select(:id))
    period_executions = executions.where(timestamp: period_range) if period_range

    {
      author: { id: author.id, name: author.name },
      total_skills: skills.count,
      total_executions: executions.count,
      total_earnings: calculate_earnings(author, period_range).to_f,
      total_slashed: calculate_slashed(author, period_range).to_f,
      average_rating: calculate_avg_rating(author),
      execution_breakdown: execution_breakdown(period_executions || executions),
      top_skills: top_skills(author, period_range),
      recent_executions: recent_executions(author, period_range)
    }
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def earnings(author_id:, period: nil)
    author = Account.find(author_id)

    unless author.id == @current_account.id
      raise AnalyticsService::Forbidden, "You can only access your own analytics"
    end

    period_range = parse_period(period)

    completed_execs = Execution.where(skill_id: author.authored_skills.select(:id), status: "completed")
    period_execs = period_range ? completed_execs.where(timestamp: period_range) : completed_execs

    daily_data = period_execs
      .includes(:skill)
      .group_by { |e| e.timestamp.to_date }
      .map { |date, execs|
        {
          date: date.to_s,
          amount: execs.sum { |e| e.skill.price_per_call.to_f }.round(2),
          execution_count: execs.size
        }
      }
      .sort_by { |d| d[:date] }

    total = daily_data.sum { |d| d[:amount] }
    avg = daily_data.size > 0 ? (total / daily_data.size).round(2) : 0.0

    skill_revenue = period_execs
      .group_by { |e| e.skill }
      .map { |skill, execs| { name: skill.name, revenue: (execs.size * skill.price_per_call.to_f).round(2) } }
      .max_by { |s| s[:revenue] }

    {
      earnings_over_time: daily_data,
      total_earnings: total,
      average_per_day: avg,
      best_skill: skill_revenue || nil
    }
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  class Forbidden < StandardError; end

  private

  # rubocop:disable Metrics/MethodLength
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
      nil
    end
  end
  # rubocop:enable Metrics/MethodLength

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

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def top_skills(author, period)
    author.authored_skills.includes(:executions, :reviews).map { |skill|
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
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
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
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end
