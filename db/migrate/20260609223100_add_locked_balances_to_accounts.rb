class AddLockedBalancesToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :locked_stake, :decimal, precision: 10, scale: 2, default: 0.0, null: false
    add_column :accounts, :escrow_balance, :decimal, precision: 10, scale: 2, default: 0.0, null: false
  end
end
