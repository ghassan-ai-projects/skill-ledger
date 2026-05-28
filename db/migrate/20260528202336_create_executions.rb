class CreateExecutions < ActiveRecord::Migration[8.1]
  def change
    create_table :executions do |t|
      t.references :skill, null: false, foreign_key: true
      t.references :buyer, null: false, foreign_key: { to_table: :accounts }
      t.string :status, null: false, default: "pending"
      t.text :result
      t.datetime :timestamp, null: false

      t.timestamps
    end
  end
end
