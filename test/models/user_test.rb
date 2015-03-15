require 'test_helper'

class UserTest < ActiveSupport::TestCase

  test "dept and organizations" do
    dept = organizations(:interior)

    u = users(:periodista)
    old_deps = u.departments.dup
    old_org_ids = u.departments.map {|d| d.organization_ids}.flatten
    u.departments << dept
    u.reload

    assert_equal (old_deps.collect(&:id)+ [dept.id]).uniq.sort, u.department_ids.sort
    assert_equal (old_deps.collect(&:id) + old_org_ids + [dept.id] + dept.organization_ids).uniq.sort , u.organization_ids.sort

    assert_equal [organizations(:educacion)], users(:periodista_educacion).departments
  end


  test 'department_events for department members' do
    u = users(:secretaria_interior)

    assert !u.department.events.blank?
  end

  test "can create permission" do
    assert users(:jefe_de_gabinete).can_create?('events'), 'Jefe de gabinete should have create events permissions'

    assert users(:jefe_de_prensa).can_create?('events'), 'Jefe de prensa should have create events permissions'


    assert users(:jefe_de_gabinete_de_interior).can_create?('events'), 'Jefe de gabinete de Interior should have create events permissions'

    assert users(:jefe_de_prensa_de_interior).can_create?('events'), 'Jefe de prensa de Interior should have create events permissions'


    assert users(:secretaria).can_create?('events'), 'Secretaria should have persmission to create events'

    assert !users(:secretaria_interior).can_create?('events'), 'Secretaria interior should not have persmission to create events'
  end

  %w(superadmin admin periodista visitante colaborador jefe_de_prensa jefe_de_gabinete secretaria comentador_oficial twitter_user facebook_user).each do |user|
    test "#{user} should be able to create comments" do
      assert users(user).can_create?("comments"), "#{user} should be able to create comments and he's not"
    end
  end

  test "miembro_que_crea_noticias should not be able to create comments" do
    assert !users(:miembro_que_crea_noticias).can_create?("comments"), "miembro_que_crea_noticias should NOT be able to create comments and he is"
  end

  if Settings.optional_modules.streaming
    test "operador_de_streaming should not be able to create comments" do
      assert !users(:operador_de_streaming).can_create?("comments"), "operador_de_streaming should NOT be able to create comments and he is"
    end
  end

  test "should reset all explicit permissions on permissions table if user role is changed" do
    # Miembro de departamento con permiso explicito para crear eventos en agencia
    user = users(:creador_eventos_irekia)
    assert_equal 1, user.permissions.count
    # El role no le atribuye ningun permiso, asi que el unico que tiene es el de la tabla "permissions"
    assert_equal 0, (user.all_permissions - user.permissions).length

    # Lo convertimos en jefe de gabinete
    user.type='StaffChief'
    assert user.save
    # tengo que volver a coger el usuario de la base de datos para que se entere de que le he cambiado el role
    user = User.find(user.id)
    assert user.is_a?(StaffChief)

    # Se resetean sus permisos en la tabla permissions
    assert_equal 0, user.permissions.count
  end

  test "admin should not be able to administer users" do
    user = users(:admin)
    assert !user.can_access?("users")
  end

  test "superadmin should not be able to administer users" do
    user = users(:superadmin)
    assert user.can_access?("users")
  end

  ["miembro_que_modifica_noticias", "admin"].each do |user|
    test "#{user} can rate recommendations" do
      user = users(user.to_sym)
      assert user.can?('rate', 'recommendations')
    end
  end

  test "miembro_que_crea_noticias cannot rate recommendations" do
    user = users(:miembro_que_crea_noticias)
    assert !user.can?('rate', 'recommendations')
  end

  test "deactivate user account" do
    user = users(:visitante)
    assert_no_difference 'User.count' do
      user.deactivate_account
    end
    user.reload
    assert_equal 'eliminado', user.status
    assert_equal I18n.t('users.eliminado'), user.public_name
    assert_equal "deleted_#{user.id}@email.com", user.email
  end

  test "new official commenter is included in official commenters list" do
    user = users(:miembro_que_crea_noticias)
    assert !User.official_commenters.include?(user)
    Permission.create(:user_id => user.id, :module => "comments", :action => "official")
    assert User.official_commenters.include?(user)
  end

  test "removing official comments permission removes user from official comments list" do
    user = users(:comentador_oficial)
    assert User.official_commenters.include?(user)
    user.permissions.where("module='comments' AND action='official'").first.destroy
    assert !User.official_commenters.include?(user)
  end

  test "new DepartmentEditor is included in official commenters list" do
    user = users(:miembro_que_crea_noticias)
    assert !User.official_commenters.include?(user)
    user.type = 'DepartmentEditor'
    user.save
    # Can't do user.reload because we have changed its class
    user = User.find(user.id)
    assert user.is_official_commenter?
    assert User.official_commenters.include?(user)
  end

  test "removing department editor removes user from official_commenters list" do
    user = users(:jefe_de_prensa_de_interior)
    assert User.official_commenters.include?(user)
    user.destroy
    assert !User.official_commenters.include?(user)
  end

  test "news for bulletin with following area" do
    area = areas(:a_lehendakaritza)
    user = users(:person_follows)
    following = Following.create(:followed_id => area.id, :followed_type => 'Area', :user_id => user.id)
    area_news = area.news.order("published_at DESC").first
    assert_equal true, News.find(user.news_for_bulletin(bulletins(:one_hour_ago).id)).collect(&:area).include?(area)
  end

  test "news for bulletin" do
    user = users(:person_follows)
    # should not include area featured news
    area = areas(:a_lehendakaritza)
    area_news = area.news.order("published_at DESC").first
    assert_equal false, user.news_for_bulletin(bulletins(:one_hour_ago)).include?(area_news)
  end

  test "bulletin_email" do
    user = users(:person_follows)
    assert_equal user.email, user.bulletin_email
  end
  
  test "user approved comments include all comments" do
    user = users(:visitante)
    approved_comments = user.approved_comments

    assert_equal true, approved_comments.detect {|comment| comment.commentable.is_a?(ExternalComments::Item)}.present?
    assert_equal true, approved_comments.detect {|comment| comment.commentable.is_a?(Document)}.present?
  end
end
