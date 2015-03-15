require 'test_helper'

class AreaTest < ActiveSupport::TestCase

  def setup
    UserActionObserver.current_user = users(:admin).id
  end

  def prepare_area()
    # En vez de crear los datos en los fixtures, asigno el tag del área lehendakaritza
    # a los contenidos con tag del Dpto. de Lehendakaritza aquí. Así sé qué contenidos entran
    # en el área sin tener que mirar en los fixtures. (eli@efaber.net)
    area = areas(:a_lehendakaritza)
    tag = tags(:lehendakaritza_tag)

    # Asignamos el tag del área a los contenidos con tag lehendakaritza
    tag.taggings.each do |t|
      if t.taggable.is_a?(News) && t.taggable.is_public?
        area.area_tag.taggings.create(:taggable_id => t.taggable_id, :taggable_type => 'Document', :context => 'tags')
      end
      if t.taggable.is_a?(Video) || t.taggable.is_a?(Photo) || t.taggable.is_a?(Album)
        area.area_tag.taggings.create(:taggable_id => t.taggable_id, :taggable_type => t.taggable_type, :context => 'tags')
      end
    end

    return [area, tag]
  end

  test "should get area newsxx" do
    area, tag = prepare_area
    area_news_in_order = area.news.order('published_at DESC')
    area_news_ids = area.news.map {|n| n.id}.sort

    # Las noticias del área son las que :
    # - tienen el tag del área
    # - están publicadas en irekia
    # - están traducidas el idioma actual
    expected_news_ids = tag.taggings.map {|t| t.taggable_id if (t.taggable.is_a?(News) && t.taggable.published? && t.taggable.translated_to?(I18n.locale.to_s))}.compact.sort
    assert_equal expected_news_ids, area_news_ids

    # Las noticias tienen que estar ordenadas por fecha desc.
    (1..area_news_in_order.length-1).each do |i|
      assert area_news_in_order[i-1].published_at >= area_news_in_order[i].published_at
    end

    # Se pueden coger un número concreto de noticias
    assert_equal 2, area.news.limit(2).length
  end

  test "should get area videos" do
    area, tag = prepare_area()
    area_videos_in_order = area.videos.order('published_at DESC')
    area_video_ids = area.videos.map {|n| n.id}.sort

    # Las noticias del área son las que :
    # - tienen el tag del área
    # - están publicadas en irekia
    # - están traducidas el idioma actual (este ed difíficl de testear así que no se comprueba aquí, eli@efaber.net)
    expected_video_ids = tag.taggings.map {|t| t.taggable_id if (t.taggable.is_a?(Video) && t.taggable.published?)}.compact.uniq.sort

    assert_equal expected_video_ids, area_video_ids

    # Los vídeos tienen que estar ordenadas por fecha desc.
    (1..area_videos_in_order.length-1).each do |i|
      assert area_videos_in_order[i-1].published_at >= area_videos_in_order[i].published_at
    end

    # Se pueden coger un número concreto de vídeos
    assert area.videos.count('distinct videos.id') > 1
    assert_equal 1, area.videos.limit(1).length

  end

  test "should get area photos" do
    area, tag = prepare_area()
    area_photos_in_order = area.photos.order('created_at DESC')
    area_photo_ids = area.photos.map(&:id).sort

    # Las noticias del área son las que :
    # - tienen el tag del área
    # - están publicadas en irekia
    expected_photo_ids = tag.taggings.map {|t| t.taggable_id if (t.taggable.is_a?(Photo) )}.compact.sort
    assert_equal expected_photo_ids, area_photo_ids

    # Los vídeos tienen que estar ordenadas por fecha desc.
    (1..area_photos_in_order.length-1).each do |i|
      assert area_photos_in_order[i-1].created_at >= area_photos_in_order[i].created_at
    end

    # Se pueden coger un número concreto de vídeos
    assert area.photos_count > 1
    assert_equal 1, area.photos.limit(1).length
  end

 if Settings.optional_modules.proposals
  test "should get area proposals" do
    area = areas(:a_lehendakaritza)
    area_proposals = area.approved_and_published_proposals.order('published_at DESC')

    # Las preguntas son las preguntas publicadas con tag del área
    expected_proposals_ids = area.area_tag.taggings.map {|t| t.taggable_id if t.taggable.is_a?(Proposal) && t.taggable.published? && t.taggable.approved?}.compact.uniq.sort
    assert_equal expected_proposals_ids, area_proposals.map {|aq| aq.id}.sort
  end
 end

 if Settings.optional_modules.debates
  test "should get area debates" do
    area = areas(:a_lehendakaritza)
    area_debates = area.published_debates.order('published_at DESC')

    # Los debates publicadas con tag del área
    expected_debates_ids = area.area_tag.taggings.map {|t| t.taggable_id if t.taggable.is_a?(Debate) && t.taggable.published?}.compact.uniq.sort
    assert_equal expected_debates_ids, area_debates.map {|aq| aq.id}.sort
  end
 end

  test "should has many followers" do
    area = areas(:a_lehendakaritza)
    user = users(:person_follows)
    following_area = Following.new(:followed_id => area.id, :followed_type => 'Area', :user_id => user.id)
    assert_equal true, following_area.save
    assert_equal [following_area], area.followings
    assert_equal [user], area.followers
  end

  test "should destroy area_users, followings and taggings on destroy" do
    area = areas(:a_lehendakaritza)
    user = users(:person_follows)
    area_user = area_users(:politician_one_lehendakaritza)
    following = Following.create(:followed_id => area.id, :followed_type => 'Area', :user_id => user.id)
    tagging = taggings(:a_lehendakaritza_tagging)

    assert_difference 'AreaUser.count', -1 do
      assert_no_difference 'User.count' do
        assert_difference 'Following.count', -1 do
          assert_difference 'ActsAsTaggableOn::Tagging.count', -1 do
            assert_no_difference 'ActsAsTaggableOn::Tag.count' do
              assert_equal area, area.destroy
            end
          end
        end
      end
    end
  end
  
  test "should update area name and keep area tag" do
    area = areas(:a_lehendakaritza)
    area_tag_name = area.area_tag_name
    
    assert area.update_attributes(:name_es => "Nuevo nombre")
    assert_equal "Nuevo nombre", area.name_es
    assert_equal area_tag_name, area.area_tag_name
  end

end
