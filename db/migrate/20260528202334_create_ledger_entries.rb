class CreateLedgerEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :ledger_entries do |t|
      t.references :from_account, null: false, foreign_key: { to_table: :accounts }
      t.references :to_account, null: false, foreign_key: { to_table: :accounts }
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :entry_type, null: false
      t.datetime :timestamp, null: false

      t.timestamps
    end
  end
end
