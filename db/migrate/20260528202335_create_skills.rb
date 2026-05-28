class CreateSkills < ActiveRecord::Migration[8.1]
  def change
    create_table :skills do |t|
      t.string :name, null: false
      t.text :description
      t.references :author, null: false, foreign_key: { to_table: :accounts }
      t.decimal :stake_amount, precision: 10, scale: 2, null: false, default: 0.0
      t.decimal :price_per_call, precision: 10, scale: 2, null: false, default: 0.0

      t.timestamps
    end
  end
end
