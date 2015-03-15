# Clase para contabilizar las sesiones que inician los usuarios
class SessionLog < ActiveRecord::Base
  belongs_to :user
end
