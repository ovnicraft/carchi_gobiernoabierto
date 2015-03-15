module Admin::CommentsHelper
  # determina la clase CSS de un comentario en el listado de la administración.
  # Sera "a_true" si el comentario es oficial, y si no el del estado del comentario
  def comment_row_class(comment_or_argument)
    "#{comment_or_argument.status} #{'official_comment' if comment_or_argument.user.is_official_commenter?}"
  end
end
