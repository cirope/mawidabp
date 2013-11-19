require 'test_helper'

# Clase para probar el modelo "EMail"
class EMailTest < ActiveSupport::TestCase
  fixtures :e_mails

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @email = EMail.find e_mails(:urgent_email).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of EMail, @email
    assert_equal e_mails(:urgent_email).to, @email.to
    assert_equal e_mails(:urgent_email).subject, @email.subject
    assert_equal e_mails(:urgent_email).body, @email.body
    assert_equal e_mails(:urgent_email).attachments, @email.attachments
    assert_equal e_mails(:urgent_email).organization_id, @email.organization_id
  end

  # Prueba la creación de una contraseña antigua
  test 'create' do
    assert_difference 'EMail.count' do
      @email = EMail.create(
        :to => 'someone@mawida.com',
        :subject => 'Some thing',
        :body => 'Some text'
      )
    end
  end

  # Prueba de actualización de una contraseña antigua
  test 'update' do
    assert @email.update(:to => 'other@mawida.com'),
      @email.errors.full_messages.join('; ')
    
    assert_equal 'other@mawida.com', @email.reload.to
  end

  # Prueba de eliminación de una contraseñas antiguas
  test 'delete' do
    assert_difference('EMail.count', -1) { @email.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @email.to = ' '
    @email.subject = ' '

    assert @email.invalid?
    assert_error @email, :to, :blank
    assert_error @email, :subject, :blank
  end
end
