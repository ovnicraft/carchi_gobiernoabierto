class RemoveInternalIdFromOrganizations < ActiveRecord::Migration
  def change
    remove_column :organizations, :internal_id
  end
end
