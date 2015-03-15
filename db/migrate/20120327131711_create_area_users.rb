class CreateAreaUsers < ActiveRecord::Migration
  def self.up
    create_table :area_users do |t|
      t.references :area
      t.references :user
      t.integer    :position, :null => false, :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :area_users
  end
end
