class AnalyticsService
  def initialize(current_account)
    @current_account = current_account
  end

  def show(author_id:, period: nil)
    author = authorized_author(author_id)
    period_range = parse_period(period)

    skills = author.authored_skills
    skill_versions = versions_for_scope(skills.select(:id))
    purchases = purchases_for_versions(skill_versions.select(:id))
    period_purchases = period_range ? purchases.where(created_at: period_range) : purchases

    {
      author: { id: author.id, name: author.name },
      total_skills: skills.count,
      listed_skills: skills.where(listing_status: "listed").count,
      verified_versions: skill_versions.where(status: "verified").count,
      total_purchases: period_purchases.count,
      total_revenue: period_purchases.sum(:amount).to_f,
      top_skills: top_skills(skills, period_purchases),
      recent_purchases: recent_purchases(period_purchases)
    }
  end

  def earnings(author_id:, period: nil)
    author = authorized_author(author_id)
    period_range = parse_period(period)

    skill_versions = versions_for_scope(author.authored_skills.select(:id))
    period_purchases = earnings_purchases_for_versions(skill_versions.select(:id))
    period_purchases = period_purchases.where(created_at: period_range) if period_range

    daily_data = period_purchases
      .group_by { |purchase| purchase.created_at.to_date }
      .map { |date, purchases|
        {
          date: date.to_s,
          amount: purchases.sum { |purchase| purchase.amount.to_f }.round(2),
          purchase_count: purchases.size
        }
      }
      .sort_by { |d| d[:date] }

    total = daily_data.sum { |d| d[:amount] }
    avg = daily_data.size > 0 ? (total / daily_data.size).round(2) : 0.0

    skill_revenue = period_purchases
      .group_by { |purchase| purchase.skill_version.skill }
      .map { |skill, purchases| { name: skill.name, revenue: purchases.sum { |purchase| purchase.amount.to_f }.round(2) } }
      .max_by { |s| s[:revenue] }

    {
      earnings_over_time: daily_data,
      total_earnings: total,
      average_per_day: avg,
      best_skill: skill_revenue || nil
    }
  end

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

  def authorized_author(author_id)
    author = Account.find(author_id)
    raise AnalyticsService::Forbidden, "You can only access your own analytics" unless author.id == @current_account.id

    author
  end

  def versions_for_scope(skill_ids)
    SkillVersion.where(skill_id: skill_ids)
  end

  def purchases_for_versions(skill_version_ids)
    Purchase.includes(:buyer, skill_version: :skill).where(skill_version_id: skill_version_ids)
  end

  def earnings_purchases_for_versions(skill_version_ids)
    Purchase.includes(skill_version: :skill).where(skill_version_id: skill_version_ids)
  end

  def top_skills(skills, purchases)
    skills.map { |skill|
      skill_purchases = purchases.select { |purchase| purchase.skill_version.skill_id == skill.id }
      top_skill_entry(skill, skill_purchases)
    }
      .sort_by { |s| -s[:purchase_count] }
      .first(5)
  end

  def recent_purchases(purchases)
    purchases.order(created_at: :desc).limit(10).map { |purchase| recent_purchase_entry(purchase) }
  end

  def top_skill_entry(skill, skill_purchases)
    {
      id: skill.id,
      name: skill.name,
      purchase_count: skill_purchases.count,
      total_revenue: skill_purchases.sum { |purchase| purchase.amount.to_f }.round(2)
    }
  end

  def recent_purchase_entry(purchase)
    {
      id: purchase.id,
      skill_name: purchase.skill_version.skill.name,
      buyer_name: purchase.buyer.name,
      version: purchase.skill_version.version,
      status: purchase.status,
      amount: purchase.amount.to_f,
      purchased_at: purchase.created_at,
      acquired_at: purchase.acquired_at
    }
  end
end
