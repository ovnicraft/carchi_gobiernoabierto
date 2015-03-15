class SetSnRobotRoleToColaborator < ActiveRecord::Migration
  def self.up
    if u = User.irekia_robot
      u.update_attribute(:type, 'Colaborator')
    end
  end

  def self.down
  end
end
