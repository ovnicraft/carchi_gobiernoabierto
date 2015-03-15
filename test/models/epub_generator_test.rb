require 'test_helper'

class EpubGeneratorTest < ActiveSupport::TestCase

  context "new" do
    setup do
      @epub = EpubGenerator.new
    end

    should "assign identifier" do
      assert @epub.identifier.present?
    end
  end

  context "export" do
    setup do
      @news1 = FactoryGirl.create(:published_news)
      @news2 = FactoryGirl.create(:published_news)

      @epub = EpubGenerator.new
      @epub.reset_skeleton!
      @export_dir = "#{Rails.root}/test/data/epub/"
      @epub.export([@news1.id, @news2.id], @export_dir)
    end

    teardown do
      FileUtils.rm_r(@export_dir)
    end

    should "generate files necessary files" do
      assert File.exists?("#{@export_dir}/irekia-epub.zip")
      EpubGenerator::LOCALES.each do |l|
        assert File.exists?("#{@export_dir}/#{l}/META-INF/container.xml")
        assert File.exists?("#{@export_dir}/#{l}/mimetype")
        assert File.exists?("#{@export_dir}/#{l}/OEBPS/content.opf")
        assert File.exists?("#{@export_dir}/#{l}/OEBPS/images/irekia-cover.jpg")
        assert File.exists?("#{@export_dir}/#{l}/OEBPS/news/cover.xhtml")
        assert File.exists?("#{@export_dir}/#{l}/OEBPS/news/news#{@news1.id}.xhtml")
        assert File.exists?("#{@export_dir}/#{l}/OEBPS/news/news#{@news2.id}.xhtml")
        assert File.exists?("#{@export_dir}/#{l}/OEBPS/news/toc.xhtml")
        assert File.exists?("#{@export_dir}/#{l}/OEBPS/toc.ncx")
        assert File.exists?("#{@export_dir}/irekia-epub/irekia_#{l}.epub")
        if File.exists?("#{EpubGenerator::PATH}/kindlegen")
          assert File.exists?("#{@export_dir}/irekia-epub/irekia_#{l}.mobi")
        end
      end
    end
  end
end
