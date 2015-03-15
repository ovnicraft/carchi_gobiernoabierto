require 'test_helper'

class AlbumsControllerTest < ActionController::TestCase
  
  test "get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:featured_album)
  end

  
  # test "draft album should not be visible" do
  #   get :index
  #   assert !assigns(:albums).include?(albums(:album_dept_interior_draft))
  # end
  
  
  test "get show" do
    get :show, :id => albums(:album_one).id
    assert_response :success
    assert 2, assigns(:photos).length
  end
  
 
  # test "get department gallery" do
  #   get :cat, :id => categories(:cat_de_fototeca_interior).id
  #   assert_response :success
  #   assert assigns(:albums)
  #   puts "AAAAAAAA #{assigns(:albums).collect(&:title).inspect}"
  #   assert_equal 2, assigns(:albums).length
  #   assert_select "div.albums" do
  #     assert_select "div.row-fluid", :count => assigns(:albums).length do
  #       assert_select "div.span3 div.image" do
  #         assert_select "a", :href => album_path(albums(:album_dept_interior))
  #       end
  #     end
  #   end
  # end
  
  test "should show category by id" do
    get :cat, :id => categories(:cat_de_fototeca_interior).id
    assert_response :success
    assert_select 'div.section_content.span8' do
      assert_select 'div.albums' do
        assert_select 'div.section_heading', :text => categories(:cat_de_fototeca_interior).name
        assert_select 'div.row-fluid', :count => categories(:cat_de_fototeca_interior).albums_count
      end
    end
    assert_select 'div.section_aside.span4' do
      assert_select 'div.aside_module.areas div.content ul.categories li', :count => Area.count 
      assert_select 'div.aside_module.categories div.content ul.categories li', :count => Album.categories.count
    end
  end
  
  
  test "draft album should not be visible" do
    get :cat, :id => categories(:cat_de_fototeca_interior).id
    assert !assigns(:albums).include?(albums(:album_dept_interior_draft))
  end
  
  test "get department gallery with no album" do
    get :cat, :id => categories(:cat_de_fototeca_lehendakaritza).id
    assert_response :success
    assert_equal 0, assigns(:albums).length
  end
  
  test "should not show emtpy album" do
    get :index
    # Even if it is featured, it is not shown
    assert assigns(:featured_album) != albums(:album_dept_interior_empty)
    # It is also not shown in the department collections list
    assert_select "div.depts_menu div.albums_box div.dept_album p.caption a", :text => albums(:album_dept_interior_empty).title_es, :count => 0
  end
  
  test "should not show emtpy album in department gallery" do
    get :cat, :id => categories(:cat_de_fototeca_interior).id
    assert assigns(:featured_album) != albums(:album_dept_interior_empty)
    assert !assigns(:albums).include?(albums(:album_dept_interior_empty))
  end
  
  test "should show index" do
    get :index
    assert_response :success
    
    assert assigns(:featured_album)
    
    assert_select "div.section_main div.section_content div.albums" do
      assert_select "div.featured_album" do
        assert_select 'div.title', :text => assigns(:featured_album).title
      end
      assert_select 'div.areas'
      assert_select "div.categories"
    end
  end
  
  test "should get area albums" do
    album_for_list = albums(:album_one)
    album_for_list.tag_list.add("_a_lehendakaritza")
    assert album_for_list.save

    get :index, :area_id => areas(:a_lehendakaritza).id
    assert assigns(:featured_album)
    assert_equal albums(:album_area_lehendakaritza), assigns(:featured_album)
    
    assert assigns(:albums)
    assert assigns(:albums).include?(album_for_list)
    assert !assigns(:albums).include?(albums(:album_two)) # Los que no son del área no salen
    
    assert_select "div.section_main div.section_content div.albums" do
      assert_select 'div.section_heading', :text => 'Destacado'
      assert_select 'div.row-fluid', :count => areas(:a_lehendakaritza).albums_count
      
      assert_select 'div.row-fluid div.span3' do
        assert_select 'div.image'
        assert_select 'div.title'
        assert_select 'div.date'
      end
    end
  end
  
  test "should track clickthrough when clicking on a search result" do
    assert_content_is_tracked(criterios(:criterio_one), albums(:album_area_lehendakaritza))
  end
  
  test "should track clickthrough when clicking on a tag item" do
    assert_content_is_tracked(tags(:viajes_oficiales), albums(:album_area_lehendakaritza))
  end
end
