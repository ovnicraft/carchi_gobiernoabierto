class CreatePermissions < ActiveRecord::Migration
  def self.up
    create_table :permissions do |t|
      t.references :user
      t.string :module
      t.string :action
      t.timestamps
    end
    execute 'ALTER TABLE permissions ADD CONSTRAINT fk_perm_user_id FOREIGN KEY (user_id) REFERENCES users(id)'
  end

  def self.down
    drop_table :permissions
  end
end
