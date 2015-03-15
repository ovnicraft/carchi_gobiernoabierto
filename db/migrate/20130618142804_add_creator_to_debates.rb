class AddCreatorToDebates < ActiveRecord::Migration
  def self.up
    add_column :debates, :created_by, :integer
    add_column :debates, :updated_by, :integer
    
    execute 'ALTER TABLE debates ADD CONSTRAINT fk_debates_created_by FOREIGN KEY (created_by) REFERENCES users(id)'
    execute 'ALTER TABLE debates ADD CONSTRAINT fk_debates_updated_by FOREIGN KEY (updated_by) REFERENCES users(id)'    
  end

  def self.down
    remove_column :debates, :updated_by
    remove_column :debates, :created_by
  end
end