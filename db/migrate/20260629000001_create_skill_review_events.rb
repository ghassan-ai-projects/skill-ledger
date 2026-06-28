class CreateSkillReviewEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :skill_review_events do |t|
      t.references :skill_review, null: false, foreign_key: true
      t.references :actor_account, foreign_key: { to_table: :accounts }
      t.string :event_type, null: false
      t.string :from_status
      t.string :to_status, null: false
      t.text :reason

      t.datetime :created_at, null: false
    end

    add_index :skill_review_events, :event_type
  end
end
