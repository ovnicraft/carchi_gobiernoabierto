# encoding: UTF-8
module DocumentsHelper
  def icon_for_document(document, html_options={})
    image_tag('gv.gif', {:width => 30, :height => 30, :alt => Settings.site_name}.merge(html_options) )
  end

  def url_for_photo(path)
    # should use URI.join but it is a little messy when using paths and endpoints all together
    # file.join works well even not being a path but a url
    File.join(Document::MULTIMEDIA_URL, relative_path_for_photo(path))
  end

  def relative_path_for_photo(path)
    path.sub(/^#{Document::MULTIMEDIA_PATH}/,'').sub(/^#{Document::MULTIMEDIA_URL}/,'')
  end

  def absolute_path_for_photo(path)
    File.join(Document::MULTIMEDIA_PATH, relative_path_for_photo(path))
  end

  def file_type(file)
    Pathname.new(file.file_file_name).extname.sub('.', '')
  end

  def subtitle_for_iphone(news)
    news.subtitle.present? ? news.subtitle.strip_html : pretty_n_characters_wo_html(news.body).strip_html
  end

  def show_left_menu_for(document)
    document.has_video? || document.has_cover_photo? || document.has_videos? ||
    document.has_audios? || document.has_photos? || document.has_files? || document.has_transcriptions?
  end

  def document_img_tag(original_photo_path, size, absolute=false)
    small_version = Tools::PhotoUtils.photo_size_path(original_photo_path, size)
    # logger.info "document_img_tag: Buscando #{small_version}"
    if original_photo_path.match(/#{default_preview_img}$/) || original_photo_path.match(/#{default_preview_img('169')}$/)
      # logger.info "document_img_tag: #{small_version} es el default"
      small_img_tag = original_photo_path
    elsif File.exists?(absolute_path_for_photo(small_version))
      # logger.info "document_img_tag: #{small_version} ya existe"
      small_img_tag = url_for_photo(small_version)
    else
      if absolute
        # logger.info "document_img_tag: #{small_version} generando absoluto :path => #{relative_path_for_photo(original_photo_path)}"
        small_img_tag = image_news_index_url(:size => size, :path => relative_path_for_photo(original_photo_path), :locale => I18n.locale)
      else
        # logger.info "document_img_tag: #{small_version} generando relativo :path => #{relative_path_for_photo(original_photo_path)}"
        small_img_tag = image_news_index_path(:size => size, :path => relative_path_for_photo(original_photo_path), :locale => I18n.locale)
      end
    end
    logger.debug "document_img_tag: Devolviendo #{small_img_tag}"
    return small_img_tag
  end

  def news_img_and_alt(news, size="n70")
    small_img_tag = nil
    alt = nil
    if news.has_video?
      # logger.info "news_img_and_alt: #{news.id} has video"
      photo = video_preview_img(news)
      small_img_tag = document_img_tag(photo, size, true)
      alt = small_img_tag.match(/([^(%2F)]+)\.jpg/).to_a[1].humanize.capitalize if small_img_tag.match(/([^(%2F)]+)\.jpg/)
    elsif news.has_cover_photo?
      # logger.info "news_img_and_alt: #{news.id} has cover photo"
      small_img_tag = "#{base_url}#{news.cover_photo.url(size.to_sym)}"
    elsif news.photos.length > 0
      # logger.info "news_img_and_alt: #{news.id} has secondary photos"
      photo = news.photos.first
      small_img_tag = document_img_tag(photo, size, true)
      alt = small_img_tag.match(/([^(%2F)]+)\.jpg/).to_a[1].humanize.capitalize if small_img_tag.match(/([^(%2F)]+)\.jpg/)
    else
      small_img_tag = case size
      when 'n70'
        if news.is_consejo_news
          asset_path("default/acuerdo_news_img_default_70.png")
        else
          asset_path("default/news_img_default_70.png")
        end
      else
        # 320x240
        asset_path("default/news_img_default.png")
      end
      alt = news.title
    end
    return {:img => small_img_tag, :alt => alt}
  end

end
