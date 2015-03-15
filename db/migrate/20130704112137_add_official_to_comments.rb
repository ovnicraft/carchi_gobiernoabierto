class AddOfficialToComments < ActiveRecord::Migration
  def self.up
    Comment.delete_all("commentable_type='Poll'")

    add_column :comments, :is_official, :boolean, :null => false, :default => false
    Comment.all.each do |comment|
      puts "Comentario #{comment.id}:"
      if comment.user_id && comment.user.is_official_commenter?
        puts "\tmarcando el comentario #{comment.id} como oficial"
        comment.is_official = true
      end
      
      begin 
        commentable = comment.commentable
      rescue ActiveRecord::SubclassNotFound  => err
        if err.to_s.match(/The single-table inheritance mechanism failed to locate the subclass: 'Question'/)
          puts "\tIgnoring comment on question #{comment.commentable_id}"
          next
        end
      end

      if commentable
        comment.commentable.areas.each do |area|
          puts "\tañadiendo area #{area.name} al comentario #{comment.id}"
          comment.tag_list.add area.area_tag.sanitized_name_es
        end
      end
      
      if comment.save
        puts "\tGuardando comentario #{comment.id}"
      else
        puts "\tNO HE PODIDO ASIGNAR ÁREA AL COMENTARIO #{comment.id}: #{comment.errors.inspect}"
      end
    end
    
    
  end

  def self.down
    remove_column :comments, :is_official
  end
  
end
