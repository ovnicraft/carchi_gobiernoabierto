class CreatePolls < ActiveRecord::Migration
  def self.up
    create_table :polls do |poll|
      poll.string :name
      poll.string :title_es
      poll.string :title_eu
      poll.string :title_en            
      poll.boolean :draft
      poll.datetime :published_at
      poll.datetime :ends_at
      poll.integer :target
      poll.integer :created_by
      poll.integer :updated_by      
      poll.timestamps
    end
    
    create_table :poll_options do |opt|
      opt.string :description_es
      opt.string :description_eu
      opt.string :description_en         
      opt.belongs_to :poll
      opt.integer :position, :default => 0, :null => false
      opt.integer :poll_answers_count, :default => 0
      opt.integer :created_by
      opt.integer :updated_by      
      opt.timestamps
    end
    
    create_table :poll_answers do |ans|
      ans.belongs_to :user
      ans.belongs_to :poll_option
      ans.string :ip, :limit => 20
      ans.datetime :created_at
    end
    
  end

  def self.down
    drop_table :polls
    drop_table :poll_options
    drop_table :poll_answers
  end
end

