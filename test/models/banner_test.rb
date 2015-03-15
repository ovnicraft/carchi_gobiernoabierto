require 'test_helper'

class BannerTest < ActiveSupport::TestCase

  test "should not save banner with blank url" do
    ban=Banner.new(:alt_es => 'Hola mundo', :logo_es => File.new(File.join(Document::MULTIMEDIA_PATH, "photos", "test-170x100.jpg")))
    assert !ban.valid?
    assert_equal ["no puede estar vacío"], ban.errors[:url_es]
  end

  test "should not save banner with invalid url" do
    ban = Banner.new :alt_es => 'Hola mundo', :url_es => 'google.com',
                     :logo_es => File.new(File.join(Document::MULTIMEDIA_PATH, "photos", "test-170x100.jpg"))
    assert !ban.valid?
    assert_equal ["no es correcta"], ban.errors[:url_es]
  end

  test "should not save banner with empty alt" do
    ban = Banner.new :url_es => 'http://www.google.es',
                   :logo_es => File.new(File.join(Document::MULTIMEDIA_PATH, "photos", "test-170x100.jpg"))
    assert !ban.valid?
    assert_equal ["no puede estar vacío"], ban.errors[:alt_es]
  end

  test "should not save banner with emtpy logo file" do
    ban=Banner.new(:alt_es => 'Hola mundo', :url_es => 'http://www.google.es')
    assert !ban.valid?
    assert_equal ["no puede estar vacío"], ban.errors[:logo_es]
  end

  test "should not save banner with incorrect content_type" do
    ban = Banner.new :alt_es => 'Hola mundo', :url_es => 'http://www.google.es',
                     :logo_es => File.new(File.join(Document::MULTIMEDIA_PATH, "test.txt"))
    assert !ban.valid?
    assert_equal ["no es un tipo de fichero válido"], ban.errors[:logo_es]
  end

  test "should not save banner with incorrect size" do
    ban = Banner.new :alt_es => 'Hola mundo', :url_es => 'http://www.google.es',
                     :logo_es => File.new(File.join(Document::MULTIMEDIA_PATH, "photos", "test.jpg"))
    assert_equal false, ban.valid?
    assert_equal ["debe tener un tamaño de 170x100px"], ban.errors[:logo_es]
  end

  test "should create banner and set its position accordingly" do
    ban=Banner.new :alt_es => 'Hola mundo', :url_es => 'http://www.google.es',
                   :logo_es => File.new(File.join(Document::MULTIMEDIA_PATH, "photos", "test-170x100.jpg"))
    last_position = Banner.order("position DESC").first.position
    assert ban.valid?
    assert ban.save
    assert_equal last_position + 1, ban.position

    # clean test assets
    dirname = File.dirname(ban.logo_es.path).split('/')[0..-1].join('/')
    assert FileUtils.rm_rf(File.dirname(dirname))
  end

end
