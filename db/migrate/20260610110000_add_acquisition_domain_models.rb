class AddAcquisitionDomainModels < ActiveRecord::Migration[8.1]
  def change
    add_column :skills, :slug, :string
    add_column :skills, :listing_status, :string, null: false, default: "draft"

    add_index :skills, :slug, unique: true
    add_index :skills, :listing_status

    create_table :skill_versions do |t|
      t.references :skill, null: false, foreign_key: true
      t.string :version, null: false
      t.text :changelog
      t.string :status, null: false, default: "draft"

      t.timestamps
    end

    add_index :skill_versions, [ :skill_id, :version ], unique: true
    add_index :skill_versions, :status

    create_table :skill_artifacts do |t|
      t.references :skill_version, null: false, foreign_key: true, index: false
      t.string :artifact_type, null: false
      t.json :manifest, null: false, default: {}
      t.string :checksum, null: false

      t.timestamps
    end

    add_index :skill_artifacts, :skill_version_id, unique: true
    add_index :skill_artifacts, :artifact_type

    create_table :skill_verifications do |t|
      t.references :skill_version, null: false, foreign_key: true, index: false
      t.string :status, null: false, default: "pending"
      t.json :checks, null: false, default: {}
      t.datetime :verified_at
      t.text :failure_reason

      t.timestamps
    end

    add_index :skill_verifications, :skill_version_id, unique: true
    add_index :skill_verifications, :status

    create_table :purchases do |t|
      t.references :buyer, null: false, foreign_key: { to_table: :accounts }
      t.references :skill_version, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :status, null: false, default: "paid"
      t.datetime :acquired_at
      t.string :entitlement_token, null: false

      t.timestamps
    end

    add_index :purchases, :entitlement_token, unique: true
    add_index :purchases, :status
    add_index :purchases, [ :buyer_id, :skill_version_id ],
              unique: true,
              where: "status = 'paid'",
              name: "index_purchases_on_buyer_and_version_paid"
  end
end
