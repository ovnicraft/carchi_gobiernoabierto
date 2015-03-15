class RecreateClickthroughs < ActiveRecord::Migration
  def self.up
    rename_table :clickthroughs, :old_clickthroughs
    execute 'alter sequence clickthroughs_id_seq rename to old_clickthroughs_id_seq'
    create_table :clickthroughs, :force => true do |t|
      t.string  :click_source_type, :null => false
      t.integer :click_source_id, :null => false
      t.string  :click_target_type
      t.integer :click_target_id
      t.string  :locale, :null => false
      t.integer :user_id
      t.string  :uuid
      t.timestamps
    end
    
    Clickthrough.find_by_sql("SELECT * FROM old_clickthroughs WHERE source_type='Search' AND target_type NOT IN ('Poll', 'Article')").each do |old_clickthrough|
      begin
        old_target_object = old_clickthrough.target_type.constantize.find(old_clickthrough.target_id)
      rescue ActiveRecord::RecordNotFound => err
        puts err
      else
        new_clickthrough = Clickthrough.new :click_source_type => 'Criterio', :click_source_id => old_clickthrough.source_id,
                             :click_target_type => old_target_object.class.base_class.to_s, :click_target_id => old_target_object.id,
                             :locale => old_clickthrough.locale, :user_id => old_clickthrough.user_id, :uuid => old_clickthrough.uuid,
                             :created_at => old_clickthrough.created_at, :updated_at => old_clickthrough.updated_at
        if new_clickthrough.save
          puts "Created clickthrough from #{new_clickthrough.click_source_type}##{new_clickthrough.click_source_id} to #{new_clickthrough.click_target_type}##{new_clickthrough.click_target_id}"
        else
          puts "Could not create clickthrough from #{new_clickthrough.click_source_type}##{new_clickthrough.click_source_id} to #{new_clickthrough.click_target_type}##{new_clickthrough.click_target_id}: new_clickthrough.errors.inspect"
        end
      end
    end
  end

  def self.down
    rename_table :old_clickthroughs, :clickthroughs
    drop_table :clickthroughs
  end
end