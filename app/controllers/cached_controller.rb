# Controlador para los keywords cacheadas

class CachedController < ApplicationController
  
  def show
    news = News.find(params[:id])
    @text = news.text_with_selected_keywords
    render :layout => false  
  end
  
end