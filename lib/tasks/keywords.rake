namespace 'keywords' do
  
  desc 'Extraer las keywords de las noticias para relacionados'
  task :extract_from_news do
    #news=News.published.translated 
    #   .where(["published_at between ? and ? ", 30.days.ago, Date.today])
    #   .order("id DESC")                      
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    total_news = News.published.translated.count
    i = 0
    while i < total_news
      News.published.translated.offset(i).limit(100).order('id ASC').each do |news|
        news.save_cached_keys if news.id != 7112
      end                                                                      
      i += 100
    end       
    puts "Finished extracting keywords from news!"
  end   
   
  desc 'Extraer las keywords de las ordenes del boletin para relacionados'
  task :extract_from_orders do   
    ActiveRecord::Base.logger = Logger.new(STDOUT)    
    total_orders = Order.count
    i = 0
    while i < total_orders
      Order.offset(i).limit(100).order('id ASC').each do |order|
        order.save_cached_keys
      end                                                                      
      i += 100
    end       
    puts "Finished extracting keywords from orders!"
  end  

  desc "Importa las noticias en índice de relacionados elastic search"
  task :index_news_to_elasticsearch do            
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    total_news = News.published.translated.count
    i = 0
    while i < total_news
      News.offset(i).limit(100).order('id ASC').each do |news|
        news.update_elasticsearch_related_server
      end                                                                      
      i += 100
    end       
    puts "Finished importing News to elastic search related index!"
  end
  
  desc "Importa las ordenes en índice de relacionados elastic search"
  task :index_orders_to_elasticsearch do
    # To redirect logger.info in models to STDOUT            
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    total_orders = Order.count
    i = 0
    while i < total_orders
      Order.offset(i).limit(100).order('id ASC').each do |order|
        order.update_elasticsearch_related_server
      end                                                                      
      i += 100
    end           
    puts "Finished importing Orders to elastic search related index!"
  end            
  
  desc "Create related index in elasticsearch server"
  task :create_index => [:environment] do
    response=Elasticsearch::Base::create_related_index
    if response
      puts "Elasticsearch related index successfully created!"
    end  
  end  
  
  desc "Delete related index in elasticsearch server"
  task :delete_index => [:environment] do 
    response=Elasticsearch::Base::delete_related_index
    if response
      puts "Elasticsearch related index successfully deleted!"
    else
      puts "Error!"  
    end
  end

  desc "Re-create elasticsearch related index and index all news and orders"
  task :export_all => [:environment, :delete_index, :create_index, :index_news_to_elasticsearch, :index_orders_to_elasticsearch] do
    puts "Finished exporting all news and orders to elasticsearch!"
  end
end
