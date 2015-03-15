require 'test_helper'

class HeadlineTest < ActiveSupport::TestCase
 if Settings.optional_modules.headlines
  test "validates presence of title" do
    ref = Headline.new(:media_name => 'Media', :source_item_id => 1, :url => 'http://www.media.com', :published_at => Date.today, :source_item_type => 'headline')
    assert_equal false, ref.save
    assert_equal ["no puede estar vacío"], ref.errors[:title]
    ref.title = 'headline 1'
    assert_equal true, ref.save    
  end                
  
  test "validates presence of media_name" do
    ref = Headline.new(:title => 'headline 1', :source_item_id => 2, :url => 'http://www.media.com', :published_at => Date.today, :source_item_type => 'headline')
    assert_equal false, ref.save
    assert_equal ["no puede estar vacío"], ref.errors[:media_name]                                                            
    ref.media_name = 'Media'
    assert_equal true, ref.save    
  end
                  
  test "validates presence of url" do
    ref = Headline.new(:title => 'headline 1', :media_name => 'Media', :source_item_id => 3, :published_at => Date.today, :source_item_type => 'headline')
    assert_equal false, ref.save
    assert_equal ["no puede estar vacío"], ref.errors[:url]
    ref.url = 'http://www.media.com'
    assert_equal true, ref.save    
  end                              
  
  test "validates presence of date" do
    ref = Headline.new(:title => 'headline 1', :media_name => 'Media', :source_item_id => 4, :url => 'http://www.media.com', :source_item_type => 'headline')
    assert_equal false, ref.save
    assert_equal ["no puede estar vacío"], ref.errors[:published_at]
    ref.published_at = Date.today
    assert_equal true, ref.save    
  end 
  
  test "validates presence of source_item_type" do
    ref = Headline.new(:title => 'headline 1', :media_name => 'Media', :source_item_id => 4, :url => 'http://www.media.com', :published_at => Date.today)
    assert_equal false, ref.save
    assert_equal ["no puede estar vacío"], ref.errors[:source_item_type]                                                            
    ref.source_item_type = 'Post'
    assert_equal true, ref.save    
  end                   
  
  test "validates presence and uniqueness of source_item_id" do
    ref = Headline.new(:title => 'headline 1', :media_name => 'Media', :published_at => Date.today, :url => 'http://www.media.com', :source_item_type => 'Headline')
    assert_equal false, ref.save
    assert_equal ["no puede estar vacío"], ref.errors[:source_item_id]                                                            
    ref.source_item_id = 10
    assert_equal false, ref.save                                                                                                   
    assert_equal ["ya está cogido"], ref.errors[:source_item_id]                                                                
    ref.source_item_id = 5
    assert_equal true, ref.save    
  end
  
  test "set draft after create" do
    ref = Headline.new(:title => 'headline 1', :media_name => 'Media', :source_item_id => 1, :url => 'http://www.media.com', :published_at => Date.today, :source_item_type => 'headline')               
    assert_equal true, ref.save
    assert_equal true, ref.draft
    ref.draft = false
    assert_equal true, ref.save
    assert_equal false, ref.draft
  end           
  
  test "assign area through tags" do
    ref = headlines(:headline_media)
    area = areas(:a_lehendakaritza)    
    ref.tag_list = tags(:a_lehendakaritza_tag).name
    assert_equal true, ref.save
    assert_equal area, ref.area
  end  
 end
end
