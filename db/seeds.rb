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
end
puts "  - Skill: #{data_analysis.name} (by #{data_analysis.author.name}, #{data_analysis.price_per_call} credits/call)"

code_review = Skill.find_or_create_by!(name: "Code Review") do |s|
  s.description = "Review pull requests for bugs, security vulnerabilities, and adherence to best practices."
  s.author = bob
  s.stake_amount = 150.00
  s.price_per_call = 35.00
end
puts "  - Skill: #{code_review.name} (by #{code_review.author.name}, #{code_review.price_per_call} credits/call)"

puts "Seeding complete!"
