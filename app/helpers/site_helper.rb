# encoding: UTF-8
module SiteHelper

  def short_body(text)
    short_body = ""
    if text.present?
      # ¡OJO! el (.+) al principio puede colgar la web si el texto de la noticia tiene html lioso
      # pero sin (.+) no sale el texto para noticias con subtítulo o entradilla. ¡REVISAR!
      text_parts = text.match(/(.*)<p.*>###<.*\/p>/m)
      #m = document.body.match(/<p.*>###<.*\/p>/m)
      if text_parts
        short_body =  text_parts.to_a[1]
      else
        clean_body = white_list(text) { |node, bad| ['object', 'img'].include?(bad) ? nil : node.to_s }
        text_paragraph = clean_body.match(/^((.{200,}?)<\/p>)/m)
        if text_paragraph
          # first paragraph longer than 200 chars
          if clean_body.length > 1000 && text_paragraph[1].length > 1000
            short_body = "#{pretty_n_characters(clean_body)}</p>"
          else
            short_body = "#{text_paragraph.to_a[2]}</p>"
          end
        else
          short_body = clean_body
        end
      end
    end
    short_body.to_s
  end

  def short_body_wo_html(text)
    short_body(text).strip_html.html_safe
  end

  # Shorten text but do not split words
  def pretty_n_characters(text, n_chars=200)
    text = text[0..n_chars].strip.sub(/\s[^\s]+$/, ' &hellip;') if text.length > n_chars
    text.gsub('###','').gsub('@@@','').strip.html_safe
  end

  def pretty_n_characters_wo_html(text, n_chars=200)
    pretty_n_characters(text, n_chars).strip_html
  end

  # Flowplayer functions

  # Si vemos el video con iPad, usamos html5. Si no, usamos el flowplayer.
  def use_flowplayer?
    !ipad_user_agent? && !iphone_user_agent? && !android_user_agent?
  end

  # Datos sobre el flowplayer que se usan para inicializarlo desde el JS
  def flowplayer_info
    # Version 3.2.15
    info = {}

    info[:path] = "/video/flowplayer-3.2.15.swf"
    info[:controls_plugin] = "/video/flowplayer.controls-3.2.14.swf"
    info[:streaming_plugin] = "/video/flowplayer.pseudostreaming-3.2.11.swf"
    info[:gatracker_plugin] = "/video/flowplayer.analytics-3.2.8.swf"
    info[:rtmp_plugin] = "/video/flowplayer.rtmp-3.2.11.swf"
    info[:captions_plugin] = "/video/flowplayer.captions-3.2.9.swf"
    info[:content_plugin] = "/video/flowplayer.content-3.2.8.swf"
    info[:key] = Rails.application.secrets["flowplayer_key"]

    info
  end

  # Devuelve el código del video para empotrar en otras webs
  def flv_video_info(item, locale=I18n.locale.to_sym)
    player_id = "lighty"
    embed_container = "video_embed_container"
    embed_id = "video_embed"

    captions_url = nil
    if item.is_a?(Video)
      video = File.join(Video::VIDEO_URL, item.featured_video.to_s)
      preview_img = video_preview_img(item, item.display_format)
      title = item.title
      duration = item.duration
      display_format = item.display_format
    elsif item.is_a?(String)
      video = File.join(Document::MULTIMEDIA_URL, item)
      embed_container = "video_embed_container_#{item.to_tag}"
      embed_id = "video_embed_#{item.to_tag}"
      player_id = "lighty_#{item.to_tag}"
      display_format = "169"
      # Este video es probablemente uno de los secundarios de una noticia, pero aquí sólo tengo el string
      # del path del video. Para sacar el título, miro a ver si tengo un objeto @news y lo saco de ahí
      if @document && @document.is_a?(News)
        info_from_webtv = video_info_from_webtv(item, @document, locale.to_s)
        title = info_from_webtv[:title]
        duration = info_from_webtv[:duration]
        display_format = info_from_webtv[:display_format]
        webtv_id = info_from_webtv[:webtv_id]
        captions_url = info_from_webtv[:captions_url]
      end
      preview_img = video_preview_img(item, display_format)
    else
      # it is a News item
      video_path = item.featured_video(locale)
      video = File.join(Document::MULTIMEDIA_URL,video_path)
      info_from_webtv = video_info_from_webtv(video_path, item, locale.to_s)
      title = info_from_webtv[:title]
      duration = info_from_webtv[:duration]
      display_format = info_from_webtv[:display_format]
      preview_img = video_preview_img(item, display_format, locale.to_s)
    end

    # como es codigo para incrustar en otras webs, las URL tienen que ser absolutas
    preview_img = preview_img.sub(/^\/assets/, "http://#{ActionMailer::Base.default_url_options[:host]}/assets")

    return {:fp_key => flowplayer_info[:key], :video => video, :preview_img => preview_img, :title => title,
            :player_id => player_id , :embed_container => embed_container, :embed_id => embed_id,
            :duration => seconds_in_minutes(duration), :display_format => display_format, :webtv_id => webtv_id,
            :captions_url => captions_url}
  end

  def photo_info(photo, document)
    if photo.respond_to?('url')
      # es foto de portada
      file_path = photo.path
      url = photo.url("original")
      title = document.present? ? document.cover_photo_alt : document.title
      gallery_id = nil
    else
      #  es un string
      file_path = photo
      url = url_for_photo(photo)
      title = document.title
      gallery_id = photo_info_from_gallery(photo, document)
    end
    return {:file_path => file_path, :url => url, :title => title, :gallery_id => gallery_id}
  end

  def photo_info_from_gallery(photo_path, item)
    if gallery_photo = item.gallery_photos.find_by_file_path(photo_without_root_path(photo_path))
      gallery_id = gallery_photo.id
    else
      gallery_id = nil
    end
  end

  def photo_without_root_path(path)
    path.gsub(Photo::PHOTOS_PATH, '')
  end

  def seconds_in_minutes(num)
    "#{num/60}:#{"%02d"%(num%60)}" unless num.nil?
  end

  def default_preview_img(format="43")
    default_img = format.eql?('169') ? asset_path("video_preview_format169.jpg") : asset_path("video_preview.jpg")
  end

  # En Floki necesitamos que el path a la imagen de portada por defecto de un video sea absoluta
  def absolutize_url(url)
    url.match(/^http/) ? url : "#{request.protocol}#{request.host_with_port}#{url}"
  end

  def video_preview_img(item, display_format=nil, locale=I18n.locale)
    if item.is_a?(Video)
      base_path = Video::VIDEO_PATH
      base_url = Video::VIDEO_URL
      video_path = item.featured_video
    elsif item.is_a?(String)
      base_path = Document::MULTIMEDIA_PATH
      base_url = Document::MULTIMEDIA_URL
      video_path = item
    else
      # it is a News item
      base_path = Document::MULTIMEDIA_PATH
      base_url = Document::MULTIMEDIA_URL
      video_path = item.featured_video(locale.to_sym)
    end

    default_img = default_preview_img(display_format)

    if video_path
      video_preview_filename = video_path.sub('.flv', '.jpg')
      video_preview_file = File.join(base_path, video_preview_filename)
      video_preview_url = File.join(base_url, video_preview_filename)
      unless File.exists?(video_preview_file)
        # Si no esta la imagen nombre_es.jpg, buscamos nombre.jpg
        preview_without_locale = video_preview_filename.sub(/_#{locale}.jpg/, '.jpg')
        if File.exists?(File.join(base_path, preview_without_locale))
          video_preview_file = File.join(base_path, preview_without_locale)
          video_preview_url = File.join(base_url, preview_without_locale)
        end
      end
      preview_img = File.exists?(video_preview_file) ? video_preview_url : default_img
    else
      preview_img = default_img
    end

  end

  def video_info_from_webtv(video_path, item, locale=I18n.locale)
    if webtv_related_video = item.webtv_videos.find_by_video_path(video_name_without_extension_and_language(video_path))
      title = webtv_related_video.send("title_#{locale}")
      duration = webtv_related_video.duration
      display_format = webtv_related_video.display_format
      webtv_id = webtv_related_video.id
      captions_url = webtv_related_video.captions_url(locale)
    else
      title = item.send("title_#{locale}")
      duration = nil
      display_format = "169"
      captions_url = nil
    end
    {:title => title, :duration => duration, :display_format => display_format, :webtv_id => webtv_id, :captions_url => captions_url}
  end

  def video_name_without_extension_and_language(video_string)
    video_string.sub(Pathname.new(video_string).extname, '').sub(/_e(s|u|n)$/, '')
  end

  def video_title_with_duration(video_info)
    txt = []
    txt.push video_info[:title]
    txt.push " [#{video_info[:duration]}]" if video_info[:duration].present?
    txt.compact.join
  end

  # Devuelve el path al video en versión HTML5
  def html5_video_for(flv_video_path)
    unless flv_video_path.nil?
      flv = Pathname.new(flv_video_path)
      "#{flv.dirname}/html5/#{flv.basename.sub(/flv$/, 'm4v')}"
    end
  end

  # Devuelve el path al video en versión para la iPhone App
  def iphone_app_video_for(flv_video_path)
    html5_video_for(flv_video_path).sub('/html5/', '/ts/').sub(/m4v$/, 'm3u8') unless flv_video_path.nil?
  end


end
