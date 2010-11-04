require 'test_helper'

# Clase para probar el modelo "FileModel"
class FileModelTest < ActiveSupport::TestCase
  fixtures :file_models

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @file_model = FileModel.find file_models(:image_file).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of FileModel, @file_model
    assert_equal file_models(:image_file).filename, @file_model.filename
    assert_equal file_models(:image_file).content_type, @file_model.content_type
    assert_equal file_models(:image_file).size, @file_model.size
  end

  # Prueba la creación de un modelo de archivo
  test 'create' do
    assert_difference 'FileModel.count' do
      @file_model = FileModel.new

      @file_model.filename = 'new_file.jpg'
      @file_model.content_type = 'image/jpeg'
      @file_model.size = 2000

      assert @file_model.save
    end
  end

  # Prueba de actualización de un modelo de archivo
  test 'update' do
    @file_model.filename = 'updated_name'
    assert @file_model.save, @file_model.errors.full_messages.join('; ')
    @file_model.reload
    assert_equal 'updated_name', @file_model.filename
  end

  # Prueba de eliminación de un modelo de archivo
  test 'delete' do
    assert_difference 'FileModel.count', -1 do
      @file_model.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validation' do
    @file_model = FileModel.new(
      :uploaded_data => Rack::Test::UploadedFile.new(make_file(1),
        'text/plain'))

    assert @file_model.valid?, @file_model.errors.full_messages.join(' ;')

    FileUtils.rm_rf File.join("#{TEMP_PATH}file_model_test"), :secure => true

    @file_model = FileModel.new(
      :uploaded_data => Rack::Test::UploadedFile.new(make_file(21),
        'text/plain'))

    assert @file_model.invalid?
    assert_equal [error_message_from_model(@file_model, :size, :inclusion)],
      @file_model.errors[:size]

    FileUtils.rm_rf File.join("#{TEMP_PATH}file_model_test"), :secure => true
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates lenght attributes' do
    @file_model.filename = 'abc' * 100
    @file_model.content_type = 'abc' * 100
    assert @file_model.invalid?
    assert_equal 2, @file_model.errors.count
    assert_equal [error_message_from_model(@file_model, :filename, :too_long,
      :count => 255)], @file_model.errors[:filename]
    assert_equal [error_message_from_model(@file_model, :content_type, :too_long,
      :count => 255)], @file_model.errors[:content_type]
  end

  private

  def make_file(size_in_mb)
    file_path = File.join "#{TEMP_PATH}file_model_test", "test#{rand(1000)}.txt"

    FileUtils.makedirs "#{TEMP_PATH}file_model_test"

    File.open file_path, 'w' do |out|
      (size_in_mb * 1024).times { out.write "#{'x' * 1023}\n" }
    end

    file_path
  end
end