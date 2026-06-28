class AddStatusToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :status, :string, default: "active", null: false
  end
end
