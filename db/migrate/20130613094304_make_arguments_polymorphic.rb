class MakeArgumentsPolymorphic < ActiveRecord::Migration
  def self.up
    add_column :arguments, :argumentable_type, :string
    rename_column :arguments, :proposal_id, :argumentable_id
    
    execute "UPDATE arguments SET argumentable_type='Contribution'"
    
    add_column :contributions, :arguments_count, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :contributions, :arguments_count
    rename_column :argumentable_id, :proposal_id
    
    remove_column :arguments, :argumentable_type
  end
end