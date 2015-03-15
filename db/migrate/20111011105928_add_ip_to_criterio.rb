class AddIpToCriterio < ActiveRecord::Migration
  def self.up
    add_column :criterios, :ip, :inet
  end

  def self.down
    remove_column :criterios, :ip
  end
end
