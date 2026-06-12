class CleanupHostedExecutionSurface < ActiveRecord::Migration[8.1]
  def change
    drop_table :reviews do |t|
      t.integer :execution_id, null: false
      t.integer :rating, null: false
      t.text :review_text
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    drop_table :executions do |t|
      t.integer :buyer_id, null: false
      t.text :result
      t.integer :skill_id, null: false
      t.string :status, default: "pending", null: false
      t.datetime :timestamp, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    rename_column :skills, :price_per_call, :price
    remove_column :skills, :stake_amount, :decimal
    remove_column :skills, :webhook_url, :string

    remove_column :accounts, :escrow_balance, :decimal
    remove_column :accounts, :locked_stake, :decimal
  end
end
