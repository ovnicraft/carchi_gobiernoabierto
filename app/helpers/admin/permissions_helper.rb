module Admin::PermissionsHelper
  
  def show_or_edit_tag_for(perm, mode="show")
    if mode.eql?("show")
      return @user.permissions_for_form_array.include?(perm) ? image_tag("admin/publish.gif") : image_tag("admin/erase.gif")
    elsif mode.eql?("edit")
      existing_perm = @user.all_permissions.detect {|p| "perm[#{p.module}][#{p.action}]".eql?(perm)}
      if existing_perm
        return check_box_tag("#{perm}", 1, true, :disabled => !existing_perm.editable)
      else
        return check_box_tag("#{perm}", 1, false, :disabled => false)
      end
    end
  end
end
