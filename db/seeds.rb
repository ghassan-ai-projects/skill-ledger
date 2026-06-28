puts "Seeding Skill-Ledger..."

# ---------------------------------------------------------------------------
# Agents (Accounts)
# ---------------------------------------------------------------------------
alice = Account.find_or_create_by!(name: "Alice") do |a|
  a.balance = 1000.00
end
puts "  - Account: #{alice.name} (#{alice.balance} credits)"
puts "    API Key: #{alice.api_key} (shown only once; save it now)" if alice.api_key

bob = Account.find_or_create_by!(name: "Bob") do |a|
  a.balance = 500.00
end
puts "  - Account: #{bob.name} (#{bob.balance} credits)"
puts "    API Key: #{bob.api_key} (shown only once; save it now)" if bob.api_key

charlie = Account.find_or_create_by!(name: "Charlie") do |a|
  a.balance = 250.00
end
puts "  - Account: #{charlie.name} (#{charlie.balance} credits)"
puts "    API Key: #{charlie.api_key} (shown only once; save it now)" if charlie.api_key

dana = Account.find_or_create_by!(name: "Dana") do |a|
  a.balance = 1000.00
end
puts "  - Account: #{dana.name} (#{dana.balance} credits)"
puts "    API Key: #{dana.api_key} (shown only once; save it now)" if dana.api_key

eve = Account.find_or_create_by!(name: "Eve") do |a|
  a.balance = 1000.00
end
puts "  - Account: #{eve.name} (#{eve.balance} credits)"
puts "    API Key: #{eve.api_key} (shown only once; save it now)" if eve.api_key

# ---------------------------------------------------------------------------
# Skills
# ---------------------------------------------------------------------------
data_analysis = Skill.find_or_initialize_by(name: "Data Analysis")
data_analysis.update!(
  description: "Analyze datasets, identify patterns, and generate comprehensive reports with visualizations.",
  author: alice,
  slug: "data-analysis",
  price: 50.00,
  listing_status: "listed"
)
puts "  - Skill: #{data_analysis.name} (by #{data_analysis.author.name}, #{data_analysis.price} credits)"

code_review = Skill.find_or_initialize_by(name: "Code Review")
code_review.update!(
  description: "Review pull requests for bugs, security vulnerabilities, and adherence to best practices.",
  author: bob,
  slug: "code-review",
  price: 35.00,
  listing_status: "listed"
)
puts "  - Skill: #{code_review.name} (by #{code_review.author.name}, #{code_review.price} credits)"

# ---------------------------------------------------------------------------
# Demo Favorites
# ---------------------------------------------------------------------------
Favorite.find_or_create_by!(account: bob, skill: data_analysis)
puts "  - Favorite: Bob favorited Data Analysis"

Favorite.find_or_create_by!(account: charlie, skill: code_review)
puts "  - Favorite: Charlie favorited Code Review"

# ---------------------------------------------------------------------------
# Demo Verified Version And Purchase
# ---------------------------------------------------------------------------
data_analysis_v1 = SkillVersion.find_or_initialize_by(skill: data_analysis, version: "1.0.0")
data_analysis_v1.status = "draft"
data_analysis_v1.save!

manifest = {
  "name" => "data-analysis",
  "description" => data_analysis.description,
  "version" => "1.0.0",
  "runtime" => "client",
  "entrypoint" => "data_analysis.execute",
  "input_schema" => { "type" => "object" },
  "output_schema" => { "type" => "object" }
}

artifact = SkillArtifact.find_or_initialize_by(skill_version: data_analysis_v1)
artifact.update!(
  artifact_type: "mcp_tool_manifest",
  manifest: manifest,
  checksum: SkillArtifactVerificationService.checksum_for_manifest(manifest)
)

SkillArtifactVerificationService.new(skill_version: data_analysis_v1).call

bob_purchase = Purchase.find_or_initialize_by(buyer: bob, skill_version: data_analysis_v1, status: "paid")
bob_purchase.amount ||= data_analysis.price
bob_purchase.acquired_at ||= Time.current
bob_purchase.save!
puts "  - Purchase: #{bob.name} acquired #{data_analysis.name} v#{data_analysis_v1.version}"

puts "Seeding complete!"
