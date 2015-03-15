require 'test_helper'

class PoliticianTest < ActiveSupport::TestCase
  
  test "should has many followers" do
    politician = users(:politician_one)
    user = users(:person_follows)
    following_politician = Following.new(:followed_id => politician.id, :followed_type => 'User', :user_id => user.id)
    assert_equal true, following_politician.save
    assert_equal [following_politician], user.followings
    assert_equal [user], politician.followers    
  end

  test "should create politician tag on create" do
    politician = Politician.new(:name => 'Nuevo', :last_names => 'Político', :email => 'nuevo_politico@test.com', :status => 'aprobado', :password => 'test', :password_confirmation => 'test', :public_role_es => 'Cargo público del político', :gc_id => '-1')
    assert politician.tag_list.empty?
  
    assert_difference 'ActsAsTaggableOn::Tag.count', 1 do  
      assert_difference 'ActsAsTaggableOn::Tagging.count', 1 do  
        assert_difference 'User.count', 1 do
          assert politician.save
        end
      end
    end
    assert_match /Nuevo Político/, politician.tag_list.join(", ")
    
    assert tag = ActsAsTaggableOn::Tag.find_by_name_es(politician.public_name)
    assert_equal 'Político', tag.kind
    assert_equal politician.id.to_s, tag.kind_info
    assert tag.translated?
  end
  
  test "change politician tag name if politician name is changed" do
    politician = users(:politician_lehendakaritza)
    tag = tags(:tag_politician_lehendakaritza)
    tag_name = tag.name
    assert_equal tag, politician.tag
    
    new_last_names = "Apellido2"
    politician.last_names = new_last_names
    assert politician.save
    
    tag.reload
    assert_equal politician.public_name, tag.name
  end

  test "delete tag if politician is deleted and no content was assigned to him" do
    politician = Politician.create(:name => 'Nuevo', :last_names => 'Político', :email => 'nuevo_politico@test.com', :status => 'aprobado', :password => 'test', :password_confirmation => 'test', :public_role_es => 'Cargo público del político', :gc_id => '-1')
    tag_id = politician.tag.id
    assert_not_nil tag_id

    assert_difference 'ActsAsTaggableOn::Tag.count', -1 do  
      politician.destroy
    end  
    
    assert !ActsAsTaggableOn::Tag.exists?(tag_id)
  end

  test "change tag type if politician is deleted and there is content assigned to him" do
    politician = users(:politician_lehendakaritza)
    tag = politician.tag
    
    assert tag.taggings.length > 1
    
    assert_no_difference 'ActsAsTaggableOn::Tag.count' do  
      politician.destroy
    end
    
    tag.reload
    
    assert tag.kind.blank?
    assert tag.kind_info.blank?
    
  end

  test "change tag type if politician user type is changed" do
    politician = users(:politician_lehendakaritza)
    tag = politician.tag

    politician.type = 'DepartmentMember'
    assert politician.save
    
    tag.reload
    
    assert tag.kind.blank?
    assert tag.kind_info.blank?
  end

  
  test "create tag if existing user is changed to politician" do
    user = users(:jefe_de_prensa)
    
    user.type = 'Politician'
    assert_difference 'ActsAsTaggableOn::Tag.count', 1 do
      assert user.save
    end
    
    # no se puede usar reload porque ha cambiado el tipo del usuario.
    user = User.find(user.id)
    
    tag = user.tag
    assert_equal 'Político', tag.kind
    assert_equal user.id.to_s, tag.kind_info
  end

  test "remove politician from area_users if user type is changed" do
    politician = users(:politician_interior_vetado)
    assert !politician.areas.empty?
    
    politician.type = 'DepartmentMember'
    assert_difference "AreaUser.count", -1 do
      assert politician.save
    end
    
   assert_nil AreaUser.find_by_user_id(politician.id)    
  end

  test "should index to elasticsearch after save" do
    prepare_elasticsearch_test
    politician = users(:politician_lehendakaritza)
    assert_deleted_from_elasticsearch politician
    assert politician.save
    assert_indexed_in_elasticsearch politician
  end

  test "should delete from elasticsearch after destroy" do
    prepare_elasticsearch_test
    politician = users(:politician_lehendakaritza)
    assert_deleted_from_elasticsearch politician
    assert politician.save
    assert_indexed_in_elasticsearch politician
    assert politician.destroy
    assert_deleted_from_elasticsearch politician
  end

  context "for given politician" do
    setup do
      @politician = users(:politician_lehendakaritza)
    end
    
    should "get news" do
      pnews = @politician.news
      
      assert_equal pnews.count, pnews.map {|n| n if n.politicians.include?(@politician)}.compact.size
    end
    
  end  
  
  context "for politician one" do
    setup do 
      @politician = users(:politician_one)
    end
    
    should "not have any permissions by default" do
      # Por defecto el político no tienen ningún permiso especial sobre noticias, eventos y comentarios
      ['news', 'events', 'comments'].each do |doc_type|
        assert !@politician.can_create?(doc_type)
        assert !@politician.can_edit?(doc_type)
      end
    end
    
    should "have permissions on news if assigned" do
      assert @politician.permissions.create(:module => 'news', :action => 'create')

      assert @politician.can_create?('news')
      assert @politician.can_edit?('news')      
    end

    should "have permissions on events if assigned" do
      assert @politician.permissions.create(:module => 'events', :action => 'create_private')
      assert @politician.permissions.create(:module => 'events', :action => 'create_irekia')

      assert @politician.can_create?('events')
      assert @politician.can_edit?('events')      
    end

    should "have permissions on comments if assigned" do
      assert @politician.permissions.create(:module => 'comments', :action => 'create')

      assert @politician.can_create?('comments')
      assert @politician.can_edit?('comments')      
    end
    
  end
  
  
end
