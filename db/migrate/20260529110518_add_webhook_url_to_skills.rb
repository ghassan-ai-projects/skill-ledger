class AddWebhookUrlToSkills < ActiveRecord::Migration[8.1]
  def change
    add_column :skills, :webhook_url, :string
  end
end
