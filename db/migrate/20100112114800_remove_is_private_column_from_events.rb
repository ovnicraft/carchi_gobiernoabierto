class RemoveIsPrivateColumnFromEvents < ActiveRecord::Migration
  def self.up
    rename_column :documents, :is_private, :is_private_deprecated
  end

  def self.down
    rename_column :documents, :is_private_deprecated, :is_private
  end
end
