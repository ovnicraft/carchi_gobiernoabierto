class ClickthroughsController < ApplicationController
  
  def track
    clickthrough = Clickthrough.new(prepare_click(params[:id]))

    # Hack para que funcione el link al mensaje del Lehendakari que han 
    # enviado en el boletin y que al parecer han sustituido por otra noticia a posteriori
    if clickthrough.click_target_id == 17404 && clickthrough.click_target_type.eql?('Document')
      clickthrough.click_target_id = 17405
    end

    if clickthrough.save
      if clickthrough.click_target_type.blank?
        #send_file("#{Rails.root}/public/assets/#{Bulletin::TRACKING_IMAGE}", :type => 'image/jpeg', :disposition => 'inline')
        send_file(File.join(Rails.root, 'public', ActionController::Base.helpers.asset_path(Bulletin::TRACKING_IMAGE, only_path: true)), :type => 'image/jpeg', :disposition => 'inline')
      else
        if clickthrough.click_target.is_a?(BulletinCopy)
          # Bulletin Copies are personalized so we don't want users to view other users'
          # bulletins by hacking urls
          redirect_to :controller => 'bulletin_copies', :action => 'show', :id => params[:id]
        else
          redirect_to clickthrough.click_target
        end
      end
    else
      logger.error "Clickthrough error for #{request.request_uri} which decodes into #{clickthrough.inspect}"
      raise ActiveRecord::RecordNotFound
    end
  end
  
  private
  
  def prepare_click(hash)
    clickthrough_info = decode_clickthrough(hash)
    click_params = {:click_source_type => 'BulletinCopy', :click_source_id => clickthrough_info[:bulletin_copy],
      :locale => I18n.locale.to_s, 
      :user_id => BulletinCopy.find(clickthrough_info[:bulletin_copy]).user_id, 
      :uuid => cookies[:openirekia_uuid]}
    unless clickthrough_info[:content_type].eql?('BulletinCopy') && clickthrough_info[:content_id].blank?
      click_params[:click_target_type] = clickthrough_info[:content_type].constantize.base_class.to_s 
      click_params[:click_target_id] = clickthrough_info[:content_id]
    end
    return click_params
  end
  
end
