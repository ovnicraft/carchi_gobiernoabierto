class DeleteXxDepartments < ActiveRecord::Migration
  def self.up
    execute 'ALTER TABLE subscriptions DROP CONSTRAINT fk_subs_department_id'
    execute 'ALTER TABLE subscriptions ADD foreign key (department_id) references organizations(id)'
    drop_table :xx_departments
    execute 'drop sequence departments_id_seq'
  end

  def self.down
  end
end
