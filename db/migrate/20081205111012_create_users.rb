class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table "users", :force => true do |t|
      t.column :name  ,                    :string
      t.column :email,                     :string
      t.column :plain_password,            :string
      t.column :crypted_password,          :string, :limit => 40
      t.column :salt,                      :string, :limit => 40
      t.column :created_at,                :datetime
      t.column :updated_at,                :datetime
      t.column :remember_token,            :string
      t.column :remember_token_expires_at, :datetime
      t.column :role,                      :string, :limit => "10", :default => "user"
      t.column :status,                    :string, :limit => "10", :default => "aprobado"
    end
    user = User.create(:name => 'Admin', :email=> "admin@efaber.net", :password => 'secret', :password_confirmation => 'secret')
    user.role='admin'
    user.save!
  end

  def self.down
    drop_table "users"
  end
end
