class CreateSubscriptions < ActiveRecord::Migration
  def self.up
    create_table :subscriptions do |t|
      t.integer :user_id, :null => false
      t.integer :department_id, :null => false
      t.timestamps
    end
    
    execute 'ALTER TABLE subscriptions ADD CONSTRAINT fk_subs_user_id FOREIGN KEY (user_id) REFERENCES users(id)'
    execute 'ALTER TABLE subscriptions ADD CONSTRAINT fk_subs_department_id FOREIGN KEY (department_id) REFERENCES departments(id)'
  end

  def self.down
    drop_table :subscriptions
  end
end
