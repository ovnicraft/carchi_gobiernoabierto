# Clase para los usuarios de tipo "Administrador". Es subclase de User, 
# por lo que su tabla es <tt>users</tt>
class Admin < User

  # Permisos heredados por los usuarios de este tipo
  def self.inherited_permissions
    [{:module => "news", :action => "create"}, {:module => "news", :action => "complete"}, {:module => "news", :action => "export"},
     {:module => "comments", :action => "edit"}, {:module => "comments", :action => "official"},
     {:module => "proposals", :action => "edit"},
     {:module => "events", :action => "create_private"}, {:module => "events", :action => "create_irekia"}]
  end
  
end
