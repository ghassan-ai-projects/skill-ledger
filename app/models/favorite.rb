class Favorite < ApplicationRecord
  belongs_to :account
  belongs_to :skill

  validates :account_id, uniqueness: { scope: :skill_id, message: "already favorited this skill" }
end
