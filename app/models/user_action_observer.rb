# Observer para poder hacer seguimiento de quién es el creador y último modificador
# de los diferentes recursos
class UserActionObserver < ActiveRecord::Observer
  # assuming these all have created_by_id and updated_by_id
  observe Document, Category, ActsAsTaggableOn::Tag, Proposal, Video, Attachment, Album, Photo, RelatedEvent, Debate

  cattr_accessor :current_user

  # Actualiza el campo <tt>updated_by</tt>
  def before_save(model)
    model.updated_by = @@current_user if model.respond_to?("updated_by")
  end
  
  # Actualiza el campo <tt>created_by</tt>
  def before_create(model)
    model.created_by = @@current_user if model.respond_to?("created_by")
  end
end

# UserActionObserver.instance
