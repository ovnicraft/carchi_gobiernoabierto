class RemoveLinks < ActiveRecord::Migration
  def self.up
    counter = 0
    Document.select("id, multimedia_path").where("type='Link'").each do |link|
      link.destroy
    end
    puts "Destroyed #{counter} links"
  end

  def self.down
  end
end
