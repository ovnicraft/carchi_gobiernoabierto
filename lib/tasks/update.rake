# encoding: UTF-8
require File.join(Rails.root, 'config', 'environment')

namespace :update do


  desc "Create all tags associated criterios"
  task :create_tag_criterio => [:environment] do
    total_tags = ActsAsTaggableOn::Tag.all_public.count
    i = 0
    while i < total_tags
      tags = ActsAsTaggableOn::Tag.order('id ASC').offset(i).limit(100)
      tags.each do |tag|
        tag.save
      end
      i += 100
    end
    puts "Finished creating tag criterios!!"
  end

  desc "Remove duplicated politicians taggings"
  task :remove_duplicated_politicians_taggings => [:environment] do
    # This is an iterative process: execute remove method. Then find method.
    # If there are any outputs you should re-execute remove method
    [News, Event, Page, Video, Proposal].each do |type|
      total = type.count
      i = 0
      while i < total do
        items = type.limit(100).offset(i).order('id ASC')
        items.each do |item|
          if item.politicians_tags.size > item.politicians_tags.uniq.compact.size
            # There are duplicated tags
            taggings = ActsAsTaggableOn::Tagging.where({:taggable_id => item.id, :taggable_type => item.class.base_class.to_s})
            dup_tagging = taggings.detect{|e| taggings.map(&:tag_id).count(e.tag_id) > 1}
            dup_tagging.destroy
            puts "Tagging##{dup_tagging.id} about #{dup_tagging.taggable_type}##{dup_tagging.taggable_id} #{dup_tagging.tag.name} has been removed"
          end
        end
        i += 100
      end
    end
  end

  desc "Find duplicated politicians taggings"
  task :find_duplicated_politicians_taggings => [:environment] do
    [News, Event, Page, Video, Proposal].each do |type|
      total = type.count
      i = 0
      while i < total do
        items = type.limit(100).offset(i).order('id ASC')
        items.each do |item|
          if item.politicians_tags.size > item.politicians_tags.uniq.compact.size
            puts "Item #{item.class.to_s}##{item.id} has duplicated politicians tags yet. #{item.politicians_tag_list}"
          end
        end
        i += 100
      end
    end
  end

end
