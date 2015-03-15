class AddSubtypeToClickthrough < ActiveRecord::Migration
  def self.up
    add_column :clickthroughs, :source_subtype, :string
    add_column :clickthroughs, :target_subtype, :string
    # Clickthrough.all.each do |c|
    #   begin 
    #     source_doc = Document.find(c.source_id)
    #     c.source_subtype = source_doc.class.to_s.downcase
    #     target_doc = Document.find(c.target_id)
    #     c.target_subtype = target_doc.class.to_s.downcase
    #     c.save
    #   rescue ActiveRecord::RecordNotFound
    #     
    #   end
    # end
  end

  def self.down
    remove_column :clickthroughs, :source_subtype
  end
end