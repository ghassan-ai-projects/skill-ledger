class AddLastUsedAtToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :last_used_at, :datetime
  end
end
