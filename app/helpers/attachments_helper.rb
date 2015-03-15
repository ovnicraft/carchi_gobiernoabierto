module AttachmentsHelper
  def link_to_add_fields(name, f, association)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render("/attachments/form", :f => builder)
    end
    link_to(name, "#", onclick: "add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\");return false;")
  end
end
