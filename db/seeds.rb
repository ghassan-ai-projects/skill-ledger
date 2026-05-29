puts "Seeding Skill-Ledger..."

# ---------------------------------------------------------------------------
# Agents (Accounts)
# ---------------------------------------------------------------------------
alice = Account.find_or_create_by!(name: "Alice") do |a|
  a.balance = 1000.00
end
puts "  - Account: #{alice.name} (#{alice.balance} credits) — API Key: #{alice.api_key}"

bob = Account.find_or_create_by!(name: "Bob") do |a|
  a.balance = 1000.00
end
puts "  - Account: #{bob.name} (#{bob.balance} credits) — API Key: #{bob.api_key}"

charlie = Account.find_or_create_by!(name: "Charlie") do |a|
  a.balance = 1000.00
end
puts "  - Account: #{charlie.name} (#{charlie.balance} credits) — API Key: #{charlie.api_key}"

diana = Account.find_or_create_by!(name: "Diana") do |a|
  a.balance = 1000.00
end
puts "  - Account: #{diana.name} (#{diana.balance} credits) — API Key: #{diana.api_key}"

eve = Account.find_or_create_by!(name: "Eve") do |a|
  a.balance = 1000.00
end
puts "  - Account: #{eve.name} (#{eve.balance} credits) — API Key: #{eve.api_key}"

# ---------------------------------------------------------------------------
# Skills
# ---------------------------------------------------------------------------
data_analysis = Skill.find_or_create_by!(name: "Data Analysis") do |s|
  s.description = "Analyze datasets, identify patterns, and generate comprehensive reports with visualizations."
  s.author = alice
  s.stake_amount = 200.00
  s.price_per_call = 50.00
  s.webhook_url = ENV["DATA_ANALYSIS_WEBHOOK_URL"]
end
puts "  - Skill: #{data_analysis.name} (by #{data_analysis.author.name}, #{data_analysis.price_per_call} credits/call)#{data_analysis.webhook_url ? " — webhook: #{data_analysis.webhook_url}" : ""}"

code_review = Skill.find_or_create_by!(name: "Code Review") do |s|
  s.description = "Review pull requests for bugs, security vulnerabilities, and adherence to best practices."
  s.author = bob
  s.stake_amount = 150.00
  s.price_per_call = 35.00
  s.webhook_url = ENV["CODE_REVIEW_WEBHOOK_URL"]
end
puts "  - Skill: #{code_review.name} (by #{code_review.author.name}, #{code_review.price_per_call} credits/call)#{code_review.webhook_url ? " — webhook: #{code_review.webhook_url}" : ""}"

# ---------------------------------------------------------------------------
# Demo Executions (for reviews)
# ---------------------------------------------------------------------------
exec1 = Execution.find_or_create_by!(skill: data_analysis, buyer: bob) do |e|
  e.status = "completed"
  e.timestamp = Time.current
end
puts "  - Execution: #{exec1.id} — #{exec1.buyer.name} bought #{exec1.skill.name} (completed)"

exec2 = Execution.find_or_create_by!(skill: code_review, buyer: charlie) do |e|
  e.status = "completed"
  e.timestamp = Time.current
end
puts "  - Execution: #{exec2.id} — #{exec2.buyer.name} bought #{exec2.skill.name} (completed)"

# ---------------------------------------------------------------------------
# Demo Reviews
# ---------------------------------------------------------------------------
unless exec1.review.present?
  Review.create!(execution: exec1, rating: 4, review_text: "Great analysis, very thorough!")
  puts "  - Review: Bob rated Data Analysis 4/5"
end

unless exec2.review.present?
  Review.create!(execution: exec2, rating: 5, review_text: "Excellent code review with detailed suggestions.")
  puts "  - Review: Charlie rated Code Review 5/5"
end

puts "Seeding complete!"
