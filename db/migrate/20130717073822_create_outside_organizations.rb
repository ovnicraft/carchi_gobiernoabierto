class CreateOutsideOrganizations < ActiveRecord::Migration
  def self.up
    create_table :outside_organizations do |t|
      t.string :name_es, :null => false
      t.string :name_eu
      t.string :name_en
      t.string :logo
      t.timestamps
    end
  end

  def self.down
    drop_table :outside_organizations
  end
end
