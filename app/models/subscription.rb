# Clase para las suscripciones de los periodistas a los diferentes departamentos
class Subscription < ActiveRecord::Base
  belongs_to :journalist, :class_name => "Journalist", :foreign_key => "user_id"
  belongs_to :department

  scope :active, -> { joins(:journalist).where("users.status='aprobado'")}

  before_destroy :delete_pending_alerts_if_required
  def delete_pending_alerts_if_required
    EventAlert.unsent.where("spammable_id=#{self.user_id} AND spammable_type='Journalist'").each do |alert|
        alert.destroy if alert.event.department.id == self.department_id
      end
  end

end
