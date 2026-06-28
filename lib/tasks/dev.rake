namespace :dev do
  desc "Rotate API keys for all accounts and print each new plaintext key once"
  task generate_api_keys: :environment do
    Account.find_each do |account|
      plaintext_api_key = SecureRandom.hex(32)
      account.update!(api_key_digest: BCrypt::Password.create(plaintext_api_key))
      puts "  Rotated API key for #{account.name}: #{plaintext_api_key}"
    end

    puts "Rotated API keys for #{Account.count} account(s). Store them now; plaintext keys are not persisted."
  end
end
