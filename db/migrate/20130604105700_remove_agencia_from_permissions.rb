class RemoveAgenciaFromPermissions < ActiveRecord::Migration
  def self.up
    Permission.delete_all("action='create_agencia'")
  end

  def self.down
  end
end
