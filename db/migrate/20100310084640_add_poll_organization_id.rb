class AddPollOrganizationId < ActiveRecord::Migration
  def self.up
    add_column :polls, :organization_id, :integer
  end

  def self.down
    remove_column :polls, :organization_id
  end
end
