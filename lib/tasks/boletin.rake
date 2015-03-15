# encoding: UTF-8
require File.join(Rails.root, 'config', 'environment')        

namespace :boletin do 
  
  # There is a bash script misc/prepare_brs_to_import.sh to extract all zip files, convert to utf and add brs end separator
  # Please, execute misc/prepare_brs_to_import.sh before these tasks
  
  desc "Import all old orders from export Boletin Oficial Pais Vasco"
  task :import_orders_from_brs => [:environment] do                            
    logfile = File.new(File.join(Rails.root, 'log/import_bopv.log'), 'a')  
    # 'Export_global_hasta30062011', 'Export_complemento_20110701_a_20111231', 'Export_global_hasta_20121031'
    ['junio'].each do |dirname|
      dirpath = File.join(Rails.root, 'data/bopv', dirname)
      Dir.entries(dirpath).sort.each do |filename|            
        filename = File.join(dirpath, filename)
        case filename             
        when /\/.*Castellano.*_utf.txt/
          Rake::Task["boletin:import_orders_es_from_brs"].execute([filename, logfile])
        when /\/.*Euskera.*_utf.txt/
          Rake::Task["boletin:import_orders_eu_from_brs"].execute([filename, logfile])          
        end  
      end  
    end      
  end  
  
  desc "Import old orders from Boletin Oficial Pais Vasco in Spanish" 
  task :import_orders_es_from_brs, [:filename, :logfile] => [:environment] do |t, args|  
    if args[0].present?
      @filename = args[0]                                        
      @logfile = args[1]
      # puts "#{@filename}"
    else    
      puts "No filename provided. Exiting..."
      exit  
    end         
    @logfile << "******* Import #{@filename} #{Time.zone.now} bopv castellano\n *******"        
    puts "Importing #{@filename} bopv castellano..."                
    # filename = File.join(Rails.root, 'data/Export_complemento_20110701_a_20111231/2011(1-7 a 31-12)castellanoHTM_utf.txt')      
    infile = File.new(@filename)    
    c = 1
    order = Order.new        
    an = ""
    infile.each do |line|
      line.strip!
      if line =~ /\*\*\* BRS DOCUMENT BOUNDARY \*\*\*/
         unless order.titulo_es.nil?  
           begin
             if order.save
               @logfile << "OK, Item #{order.no_orden} has been successfully saved\n"
             else
               @logfile << "ERROR, There were some errors saving #{order.no_orden} #{order.errors.full_messages}\n"  
             end  
           rescue => e
             @logfile << "ERROR RESCUE, There were some errors saving #{order.no_orden} #{e}\n"  
           end  
         end
         @logfile << "---- new BRS document started #{c}\n"
         c += 1
         order = Order.new
         next
      end
    
      an = Order.match_attribute_in_es(an, line)
      
      cleared_line = line.sub(/\..*:/, '')
      if cleared_line.present?
        if order.send(an).nil?        
          order.send("#{an}=", cleared_line) 
        else                                  
          order.send("#{an}=", order.send(an) + " " + cleared_line) 
        end
      end  
    end         
    puts "Finished!!"     
  end       
  
  desc "Import old orders from Boletin Oficial Pais Vasco in Basque" 
  task :import_orders_eu_from_brs, [:filename, :logfile] => [:environment] do |t, args|                 
    if args[0].present?
      @filename = args[0]                                        
      @logfile = args[1]
      # puts "#{@filename}"
    else    
      puts "No filename provided. Exiting..."
      exit  
    end
    @logfile << "******* Import #{@filename} #{Time.zone.now} bopv euskara\n *******"                 
    puts "Importing #{@filename} bopv euskara..."                                                                                               
    # infilename = File.join(Rails.root, 'data/Export_complemento_20110701_a_20111231/2011(1-7 a 31-12)euskeraHTM_utf.txt')
    infile = File.new(@filename)    
    c = 1
    order = Order.new        
    an = ""
    infile.each do |line|
      line.strip!
      if line =~ /\*\*\* BRS DOCUMENT BOUNDARY \*\*\*/
         unless order.titulo_eu.nil?     
           begin
             if order.save
               @logfile << "OK, Item #{order.no_orden} has been successfully saved\n"
             else                     
               if order.errors[:no_orden].include?('ya está cogido')
                 old_order = Order.where({:no_orden => order.no_orden}).first
                 h = Hash.new
                 order.attributes.map{|k, v| h[k]=v if v.present? && k.match(/eu$/)}
                 if old_order.update_attributes(h)
                   @logfile << "OK, Item #{order.no_orden} has been successfully updated in eu\n"
                 else
                   @logfile << "ERROR, There were some errors updating #{order.no_orden} #{order.errors.full_messages}\n"                   
                 end    
                 order = old_order
               end  
             end  
           rescue => e
             @logfile << "ERROR RESCUE, There were some errors updating #{order.no_orden} #{e}\n"  
           end    
         end
         @logfile << "---- new BRS document started #{c}\n"
         c += 1
         order = Order.new
         next
      end

      an = Order.match_attribute_in_eu(an, line)

      cleared_line = line.sub(/\..*:/, '') 
      if cleared_line.present?
        if order.send(an).nil?        
          order.send("#{an}=", cleared_line) 
        else
          order.send("#{an}=", order.send(an) + " " + cleared_line) 
        end
      end  
    end
    puts "Finished!!"
  end                      
  
  desc "Clean titulo_eu html"
  task :clean_titulo_eu => [:environment] do
    Order.all.each do |order|
      order.update_attribute(:titulo_eu, order.titulo_eu.strip.strip_html) if order.titulo_eu.present?
    end                                                                                               
    puts "Finished!"
  end  
  
end
