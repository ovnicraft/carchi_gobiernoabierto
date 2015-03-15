module Admin::UsersHelper
  def user_types_for_select
    User::TYPES.invert.sort {|a, b| a[1] <=> b[1]}
  end
end
