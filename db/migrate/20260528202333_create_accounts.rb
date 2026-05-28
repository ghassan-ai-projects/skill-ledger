class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.decimal :balance, precision: 10, scale: 2, null: false, default: 0.0

      t.timestamps
    end
  end
end
