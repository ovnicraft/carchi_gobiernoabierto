class MigrateActsAsTaggableOnSteroidsToActsAsTaggableOn < ActiveRecord::Migration
  def up
    change_table :taggings do |t|
      t.references :tagger, :polymorphic => true
      t.string :context, :limit => 128
      t.index [:taggable_id, :taggable_type, :context]
    end
    ActsAsTaggableOn::Tagging.all.each {|t| t.update_attribute :context, 'tags'}
  end
 
  def down
  end
end
