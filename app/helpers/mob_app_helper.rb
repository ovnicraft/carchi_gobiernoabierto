module MobAppHelper
  
  def current_version_supports_links
    if floki_user_agent? 
     user_agent = request.env["HTTP_USER_AGENT"].split(/ /)[0].match(/(Irekia|Floki)\/([0-9.]+)/)
     unless user_agent.nil?
       version = user_agent[2].to_f
       if version >= 2.5
         return true
       else
         return false
       end    
     end  
    end
  end

end
