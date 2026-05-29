class AddApiKeyToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :api_key, :string

    # Backfill existing records before adding constraints
    Account.reset_column_information
    Account.where(api_key: nil).find_each do |account|
      account.update!(api_key: SecureRandom.hex(32))
    end

    change_column_null :accounts, :api_key, false
    add_index :accounts, :api_key, unique: true
  end
end
