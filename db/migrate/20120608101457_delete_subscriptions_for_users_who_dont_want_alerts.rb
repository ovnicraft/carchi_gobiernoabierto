class DeleteSubscriptionsForUsersWhoDontWantAlerts < ActiveRecord::Migration
  def self.up
    Journalist.all.each do |journalist|
      if journalist.subscriptions.count > 0 && !journalist.has_event_alerts?
        puts "borrando suscripciones de #{journalist.email}"
        journalist.subscriptions = []
        journalist.save
      end
    end
    remove_column :users, :has_event_alerts
  end

  def self.down
    add_column :users, :has_event_alerts, :boolean, :default => false,      :null => false
  end
end
