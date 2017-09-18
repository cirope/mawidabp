require 'test_helper'

# Clase para probar el modelo "Comment"
class CommentTest < ActiveSupport::TestCase
  fixtures :comments

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @comment = Comment.find comments(:comment_one).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Comment, @comment
    assert_equal comments(:comment_one).comment, @comment.comment
    assert_equal comments(:comment_one).commentable_id, @comment.commentable_id
    assert_equal comments(:comment_one).commentable_type,
      @comment.commentable_type
    assert_equal comments(:comment_one).user_id, @comment.user_id
  end

  # Prueba la creación de un comentario
  test 'create' do
    assert_difference 'Comment.count' do
      @comment = Comment.new(
        :comment => 'New comment',
        :commentable => findings(:unconfirmed_for_notification_weakness),
        :user => users(:administrator_user)
      )

      assert @comment.save, @comment.errors.full_messages.join('; ')
      assert_equal 'New comment', @comment.comment
    end
  end

  # Prueba de actualización de un comentario
  test 'update' do
    assert @comment.update(:comment => 'Updated comment'),
      @comment.errors.full_messages.join('; ')
    @comment.reload
    assert_equal 'Updated comment', @comment.comment
  end

  # Prueba de eliminación de comentarios
  test 'destroy' do
    assert_difference('Comment.count', -1) { @comment.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @comment.comment = ' '

    assert @comment.invalid?
    assert_error @comment, :comment, :blank
  end
end
