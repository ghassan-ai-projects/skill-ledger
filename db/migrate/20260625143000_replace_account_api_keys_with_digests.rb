require "bcrypt"

class ReplaceAccountApiKeysWithDigests < ActiveRecord::Migration[8.1]
  class MigrationAccount < ApplicationRecord
    self.table_name = "accounts"
  end

  def up
    add_column :accounts, :api_key_digest, :string
    add_index :accounts, :api_key_digest

    MigrationAccount.reset_column_information
    MigrationAccount.find_each do |account|
      next if account.api_key.blank?

      account.update_columns(api_key_digest: BCrypt::Password.create(account.api_key))
    end

    change_column_null :accounts, :api_key_digest, false
    remove_index :accounts, :api_key if index_exists?(:accounts, :api_key)
    remove_column :accounts, :api_key, :string
  end

  def down
    add_column :accounts, :api_key, :string

    MigrationAccount.reset_column_information
    MigrationAccount.find_each do |account|
      account.update_columns(api_key: SecureRandom.hex(32))
    end

    change_column_null :accounts, :api_key, false
    add_index :accounts, :api_key, unique: true
    remove_index :accounts, :api_key_digest if index_exists?(:accounts, :api_key_digest)
    remove_column :accounts, :api_key_digest, :string
  end
end
