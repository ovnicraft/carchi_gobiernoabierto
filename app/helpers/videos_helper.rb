module VideosHelper
  def subtitle_for_podcast(video)
    (common = video.tag_list & Department.tag_names).length > 0 ? Department.find_by_tag_name(common.first).name : nil
  end
  
  def summary_for_podcast(video)
    video.document_id ? short_body_wo_html(Document.find(video.document_id).body) : nil
  end
  
  def build_video_cuepoint_overlay(video, criterio)                                               
    keyword = criterio.get_keywords
    if video.duration.present? && keyword.present? 
      overlay_width = 325 #in px    
      video_width = video.duration # in sec                                                       
      # quitamos un pixel para que el caption muestre la palabra en cuestion
      times_in_px = video.get_times_from_keyword(keyword).map{|a| (overlay_width*a/video_width) - 1}              
      drawing_coord, drawing_coord_footer = [], []                                                                    
      drawing_coord = times_in_px.map{|a| "-draw 'line #{a},0,#{a},15'"}
      drawing_coord_footer = times_in_px.map{|a| a+=40}.map{|a| "-draw 'line #{a},0,#{a},25' -draw \"stroke red fill red translate #{a},10 rotate -90 path 'M 10,0  l -15,-5  +5,+5  -5,+5  +15,-5 z'\""}    
      filename = "/tmp/timeline_cues#{Time.zone.now.to_i}.png"
      # not working in ejie server xc:gray -transparent gray             
      system "convert -size #{overlay_width}x15 xc:#262626 -fill red #{drawing_coord.join(' ')} #{File.join(Rails.root, 'public', filename)}"    
      # arrow_head="path 'M 10,0  l -15,-5  +5,+5  -5,+5  +15,-5 z'"
      # convert -size 341x25 xc:gray -transparent white -fill red -draw 'line 100,0,100,25' -draw "stroke red fill red translate 100,10 rotate -90 $arrow_head" canvas.png    
      filename_footer = "/tmp/timeline_cues_footer#{Time.zone.now.to_i}.png"   
      system "convert -size 600x25 xc:white -fill red #{drawing_coord_footer.join(' ')} #{File.join(Rails.root, 'public', filename_footer)}"                                     
      
      return [filename, filename_footer]    
      
    else
      return ["", ""]
    end    
  end  
  
  def link_to_category_of_type(type, category)
    # type should be 'videos' or 'albums'
    if category.is_a?(Category)
      url_to_category = url_for(:controller => type, :action => "cat", :id => category)
    else
      url_to_category = url_for(:controller => type, :action => "index", :area_id => category, :anchor => "middle")
    end
    counter = category.send("#{type}_count")
    link_to("#{t("#{type}.see_all")} (#{t("#{type}.count", :count =>  (counter > 0) ? counter : 0)})", url_to_category)
  end
  
end
