class AddEnetWorkareaToDepartments < ActiveRecord::Migration
  def self.up
    add_column :organizations, :enet_workarea, :string
    Organization.update_all("enet_workarea='wprcog16'", "parent_id IS NULL")
  end

  def self.down
    remove_column :organizations, :enet_workarea
  end
end
