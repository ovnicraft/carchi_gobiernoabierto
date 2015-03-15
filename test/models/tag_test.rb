require 'test_helper'

class TagTest < ActiveSupport::TestCase

  test "translates name" do
    tag = tags(:tag_prueba)    
    I18n.locale = :es
    assert_equal tag.name_es, tag.name
    I18n.locale = :eu
    assert_equal tag.name_eu, tag.name
    I18n.locale = :en
    assert_equal tag.name_en, tag.name
    I18n.locale = :es
  end

  test "translates sanitized_name" do
    tag = tags(:tag_prueba)    
    I18n.locale = :es
    assert_equal tag.sanitized_name_es, tag.sanitized_name
    I18n.locale = :eu
    assert_equal tag.sanitized_name_eu, tag.sanitized_name
    I18n.locale = :en
    assert_equal tag.sanitized_name_en, tag.sanitized_name    
    I18n.locale = :es
  end

  test "belongs to criterio" do
    tag = tags(:tag_prueba)
    criterio = criterios(:criterio_for_tag)
    assert_equal criterio, tag.criterio
  end

  test "has many clicks from" do
    tag = tags(:tag_prueba)
    assert_equal 1, tag.clicks_from.count
  end

  test "validates presence of name_es name_eu name_en" do
    tag = ActsAsTaggableOn::Tag.new
    assert_equal false, tag.save
    assert_equal [I18n.t('activerecord.errors.messages.must_have_translation')], tag.errors[:name_es]
    assert_equal [I18n.t('activerecord.errors.messages.must_have_translation')], tag.errors[:name_eu]
    assert_equal [I18n.t('activerecord.errors.messages.must_have_translation')], tag.errors[:name_en]
  end

  test "do not validate name uniqueness" do
    tag = tags(:tag_prueba)
    tag2 = ActsAsTaggableOn::Tag.new(:name_es => tag.name_es, :name_eu => tag.name_eu, :name_en => tag.name_en)
    assert_equal true, tag2.save
  end

  test "before validation set names in every language" do
    tag = ActsAsTaggableOn::Tag.new
    tag.name_es = 'my_tag'
    assert_equal nil, tag.name_eu
    assert_equal nil, tag.name_en
    assert_equal true, tag.save
    assert_equal 'my_tag', tag.name_eu
    assert_equal 'my_tag', tag.name_en
  end

  test "set sanitized names" do
    tag = ActsAsTaggableOn::Tag.new
    tag.name_es = 'my-tag'
    assert_equal nil, tag.sanitized_name_es
    assert_equal true, tag.save
    assert_equal 'mytag', tag.sanitized_name_es
    assert_equal 'mytag', tag.sanitized_name_eu
    assert_equal 'mytag', tag.sanitized_name_en
  end

  test "create associated criterio" do
    tag = ActsAsTaggableOn::Tag.new(name_es: 'my_tag')
    assert_difference 'Criterio.count', +1 do
      assert_equal true, tag.save
    end
    criterio = Criterio.last
    assert_equal criterio, tag.criterio
    assert_equal 'tags: my_tag|my_tag|my_tag', criterio.title
  end

  test "do not create associated criterio for private tag" do
    tag = ActsAsTaggableOn::Tag.new(name_es: '_my_tag')
    assert_no_difference 'Criterio.count' do
      assert_equal true, tag.save
    end    
  end

  test "update associated criterio" do
    tag = tags(:tag_prueba)
    assert_equal true, tag.criterio.present?
    criterio = tag.criterio
    tag.name_es = 'new_name'
    assert_equal true, tag.save
    criterio.reload
    assert_equal 'tags: Test|new_name|Froga', criterio.title
  end

  test "set translated attribute if all different on update" do
    tag = ActsAsTaggableOn::Tag.new(name_es: 'tag_es')
    assert_equal true, tag.save
    assert_equal true, tag.update_attributes(name_eu: 'tag_eu', name_en: 'tag_en')
    assert_equal true, tag.translated
  end

  test "do not set translated attribute if equal on update" do
    tag = ActsAsTaggableOn::Tag.new(name_es: 'tag_es')
    assert_equal true, tag.save
    assert_equal true, tag.update_attributes(name_eu: 'tag_es', name_en: 'tag_es')
    assert_equal false, tag.translated
  end  

  test "scope all_public" do
    public_tag = tags(:tag_prueba)
    assert_equal true, ActsAsTaggableOn::Tag.all_public.include?(public_tag)
  end

  test "scope all_private" do
    private_tag = tags(:educacion_tag)
    assert_equal true, ActsAsTaggableOn::Tag.all_private.include?(private_tag)
  end

  test "scope politicians" do
    politicians_tag = tags(:tag_politician_lehendakaritza)
    assert_equal true, ActsAsTaggableOn::Tag.politicians.include?(politicians_tag)    
  end

  # How could I test this?
  # test "reindex tagged documents after update" do
  # end
end
