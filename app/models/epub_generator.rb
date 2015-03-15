class EpubGenerator

  EpubGenerator::PATH = News::EPUB_PATH
  EpubGenerator::LOCALES = %w(es eu)
  attr_accessor :identifier

  def initialize
    @av = ActionView::Base.new(Rails.root.join('app', 'views'))
    @av.class_eval do
      include ApplicationHelper
      include Admin::AdminHelper
      include SiteHelper
      include Rails.application.routes.url_helpers
    end
    @identifier = SecureRandom.uuid
  end

  def reset_skeleton!
    FileUtils.rm(File.join(EpubGenerator::PATH, "irekia-epub.zip")) if File.exists?(File.join(EpubGenerator::PATH, "irekia-epub.zip"))
    FileUtils.rm(Dir.glob(File.join(EpubGenerator::PATH, "irekia-epub", "*")))
    [:eu, :es].each do |l|
      lang_dir = File.join(EpubGenerator::PATH, l.to_s)
      FileUtils.mkdir_p(lang_dir)
      FileUtils.rm_r(Dir.glob(File.join(lang_dir, "*")))
    end
  end

  def export(news_ids, export_dir=EpubGenerator::PATH)
    export_dir ||= EpubGenerator::PATH

    if !export_dir.eql?(EpubGenerator::PATH)
      FileUtils.cp_r(File.join(EpubGenerator::PATH, "."), export_dir)
    end

    content_dir = File.join(export_dir, "OEBPS")

    self.reset_skeleton!

    system_output = ''
    EpubGenerator::LOCALES.each do |l|
      lang_dir = File.join(export_dir, l)

      # FileUtils.mkdir_p(lang_dir)
      # FileUtils.rm_r(Dir.glob("#{lang_dir}*"))
      # FileUtils.rm("#{export_dir}/irekia-epub.zip") if File.exists?("#{export_dir}/irekia-epub.zip")
      # FileUtils.rm(Dir.glob("#{export_dir}/irekia-epub/*"))

      FileUtils.cp_r(File.join(export_dir, "skeleton", "."), lang_dir)
      content_dir = File.join(lang_dir, "OEBPS")
      news = News.find(news_ids)
      File.open(File.join(content_dir, "content.opf"), 'w') do |f|
        f.write(@av.send("render", :partial => "sadmin/news/epub/content.opf.builder", :locals => {:news => news, :locale => l, :identifier => @identifier}, :layout => false))
      end

      File.open(File.join(content_dir, "toc.ncx"), 'w') do |f|
        f.write(@av.send("render", :partial => "sadmin/news/epub/toc.ncx.builder", :locals => {:news => news, :locale => l, :identifier => @identifier}, :layout => false))
      end

      if news_ids.length > 1
        File.open(File.join(content_dir, "news", "cover.xhtml"), 'w') do |f|
          f.write(@av.send("render", :partial => "sadmin/news/epub/cover.html.erb", :locals => {:locale => l}, :layout => false))
        end

        File.open(File.join(content_dir, "news", "toc.xhtml"), 'w') do |f|
          f.write(@av.send("render", :partial => "sadmin/news/epub/toc.html.erb", :locals => {:news => news, :locale => l}, :layout => false))
        end
      end

      News.find(news_ids).each do |news|
        File.open(File.join(content_dir, "news", "news#{news.id}.xhtml"), 'w') do |f|
          f.write(@av.send("render", :partial => "sadmin/news/epub/news.html.erb", :locals => {:news => news, :locale => l, :av => @av}, :layout => false))
        end
        if news.has_cover_photo?
          FileUtils.cp(news.cover_photo.path(:n770), File.join(content_dir, "images", "news#{news.id}.jpg")) if File.exists?(news.cover_photo.path(:n770))
        end
      end

      FileUtils.cd(lang_dir)
      system_output << `zip -0Xq irekia_#{l}.epub mimetype`
      system_output << `zip -Xr9Dq irekia_#{l}.epub *`
      if File.exists?("#{EpubGenerator::PATH}/kindlegen")
        system_output << `#{EpubGenerator::PATH}/kindlegen irekia_#{l}.epub`
      else
        ActiveRecord::Base.logger.info "\n----------------\n
        Warning! Mobi version could not be generated because you don't have kindlegen installed\n
        Get it at http://www.amazon.com/gp/feature.html?docId=1000765211 and copy it to #{EpubGenerator::PATH}\n
        ----------------\n"
      end
    end
    FileUtils.cd(export_dir)
    FileUtils.mv(Dir.glob(File.join("**", "*.{epub,mobi}")), 'irekia-epub/')

    system_output << `zip irekia-epub.zip irekia-epub/*`

    FileUtils.cd(Rails.root)
    return File.join(export_dir, "irekia-epub.zip")


  end

end
