class CreateFavorites < ActiveRecord::Migration[8.1]
  def change
    create_table :favorites do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.references :skill, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :favorites, [ :account_id, :skill_id ], unique: true
  end
end
