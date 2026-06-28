class CreateSkillReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :skill_reviews do |t|
      t.references :skill_version, null: false, foreign_key: true, index: { unique: true }
      t.string :status, default: "pending", null: false
      t.string :review_type, null: false
      t.references :reviewer_account, foreign_key: { to_table: :accounts }
      t.json :policy_checks, default: {}, null: false
      t.text :decision_reason
      t.datetime :submitted_at
      t.datetime :decided_at

      t.timestamps
    end

    add_index :skill_reviews, :status
  end
end
