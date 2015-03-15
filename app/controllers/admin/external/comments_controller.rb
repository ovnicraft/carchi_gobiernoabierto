class Admin::External::CommentsController < Admin::CommentsController  

  private

  #
  # Comentarios externos desde clientes que corresponden al departamento del current_user.
  # Se cogen los comentarios de clientes del departamento indicado y de las entidades 
  # que dependen de este departamento.
  #
  def query_for_department(department_tag_id, additional_conditions="")
    organizations = [@department.id]
    @department.organizations.each do |org|
      organizations.push org.id
    end
    query = "SELECT comments.id, comments.commentable_id, commentable_type,
        comments.status, body, comments.name, user_id, comments.email, comments.created_at
      FROM comments 
        INNER JOIN external_comments_items ON (comments.commentable_id = external_comments_items.id)
        INNER JOIN external_comments_clients ON (external_comments_items.client_id = external_comments_clients.id)
      WHERE commentable_type = 'ExternalComments::Item' 
            AND external_comments_clients.organization_id IN (#{organizations.join(", ")})
            AND #{additional_conditions[0]}
      ORDER BY comments.created_at DESC"
    
    [query, additional_conditions[1]]
  end
  
  def set_comments_finder
    @comments_finder = Comment.external
  end
  
  def set_commentable_type
    @commentable_type = "ExternalComments::Item"
  end
  
  def rewrite_current_tab
    @current_tab = :comments
  end

end

