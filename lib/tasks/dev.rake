namespace :dev do
  desc "Generate API keys for accounts that are missing them"
  task generate_api_keys: :environment do
    count = 0
    Account.where(api_key: nil).find_each do |account|
      account.update!(api_key: SecureRandom.hex(32))
      count += 1
      puts "  Generated API key for #{account.name}: #{account.api_key}"
    end

    if count.zero?
      puts "All accounts already have API keys."
    else
      puts "Generated #{count} API key(s)."
    end
  end
end
