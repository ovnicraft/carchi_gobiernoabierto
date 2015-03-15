# encoding: UTF-8
namespace :elasticsearch do

  ######## IREKIA ########
  desc "Recreate Irekia index in elasticsearch server"
  task :irekia_export_all => [:environment, :delete_index, :create_index, :index_items] do
    puts "Finished!"
  end
  
  desc "Create Irekia index in elasticsearch server"
  task :create_index => [:environment] do
    response = Elasticsearch::Base::create_index
    Elasticsearch::Base::log "Irekia index was successfully created. " if response
  end  
  
  desc "Export all active items to Irekia index elasticsearch server"
  task :index_items => [:environment] do                                           
    count = 0
    [News, Event, Page, Proposal, Video, Album, Debate].each do |type|                    
      i = 0
      while i < type.published.count                                                                
        type.published.offset(i).limit(100).order('id ASC').each do |item|
          item.update_elasticsearch_server           
          count+=1
        end
        i+=100  
      end
    end 
    Politician.approved_or_ex.each do |item|
      item.update_elasticsearch_server
      count+=1
    end
    Elasticsearch::Base::log "#{count} items were successfully exported to Irekia index. "
  end
  
  desc "Delete Irekia index from elasticsearch server"
  task :delete_index => [:environment] do 
    response=Elasticsearch::Base::delete_index
    if response
      Elasticsearch::Base::log "Irekia index was successfully deleted. "
    else
      Elasticsearch::Base::log "Error deleting Irekia index. "  
    end
  end

  desc "Import to elasticsearch server recently published items" 
  task :import_recently_published => [:environment] do
    [News, Event, Page, Proposal, Video, Debate].each do |type|
      type.where(["published_at > ? AND published_at > updated_at", 6.hour.ago]).each do |item|
        item.update_elasticsearch_server
        if item.is_a?(News)
          item.update_elasticsearch_related_server
        end
      end
    end
  end
  
  ######## BOPV ########
  desc "Recreate Bopv index in elasticsearch"
  task :bopv_export_all => [:environment, :delete_bopv_index, :create_bopv_index, :index_items_to_bopv] do
    Elasticsearch::Base::log "Finished!"
  end       
  
  desc "Create Bopv index in elasticsearch server"
  task :create_bopv_index => [:environment] do
    response=Elasticsearch::Base::create_bopv_index
    Elasticsearch::Base::log "Elasticsearch Bopv index was successfully created. " if response
  end    
  
  desc "Export all orders to Bopv elasticsearch server"
  task :index_items_to_bopv => [:environment] do 
    total_orders = Order.count
    i = 0
    count = 0
    while i < total_orders 
      Order.order("id ASC").offset(i).limit(100).each do |item|
        item.update_elasticsearch_server
        count += 1
      end                  
      i += 100
    end  
    Elasticsearch::Base::log "#{count} orders were successfully exported to Bopv index. "
  end
  
  desc "Delete Bopv index from elasticsearch server"
  task :delete_bopv_index => [:environment] do 
    response=Elasticsearch::Base::delete_bopv_index
    if response
      Elasticsearch::Base::log "Elasticsearch Bopv index was successfully deleted. "
    else
      Elasticsearch::Base::log "Error deleting Bopv index. "  
    end
  end

end
