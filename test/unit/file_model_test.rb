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
    assert_equal file_models(:image_file).file_file_name, @file_model.file_file_name
    assert_equal file_models(:image_file).file_content_type, @file_model.file_content_type
    assert_equal file_models(:image_file).file_file_size, @file_model.file_file_size
  end

  # Prueba la creación de un modelo de archivo
  test 'create' do
    assert_difference 'FileModel.count' do
      @file_model = FileModel.new

      @file_model.file_file_name = 'new_file.jpg'
      @file_model.file_content_type = 'image/jpeg'
      @file_model.file_file_size = 2000

      assert @file_model.save
    end
  end

  # Prueba de actualización de un modelo de archivo
  test 'update' do
    @file_model.file_file_name = 'updated_name.txt'
    assert @file_model.save, @file_model.errors.full_messages.join('; ')
    @file_model.reload
    assert_equal 'updated_name.txt', @file_model.file_file_name
  end

  # Prueba de eliminación de un modelo de archivo
  test 'delete' do
    assert_difference 'FileModel.count', -1 do
      @file_model.destroy
    end
  end
  
  test 'delete file when remove_file is one' do
    assert_difference 'FileModel.count' do
      file = Rack::Test::UploadedFile.new(
        "#{self.class.fixture_path}/files/test.txt", 'text/plain'
      )

      @file_model = FileModel.create(:file => file)
    end
    
    assert @file_model.file?
    assert @file_model.update_attributes(:remove_file => '1')
    assert !@file_model.file?
    
    FileUtils.rm_rf File.join("#{TEMP_PATH}file_model_test"), :secure => true
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates lenght attributes' do
    @file_model.file_file_name = "#{'abc' * 100}.txt"
    @file_model.file_content_type = 'abc' * 100
    assert @file_model.invalid?
    assert_equal 2, @file_model.errors.count
    assert_equal [error_message_from_model(@file_model, :file_file_name, :too_long,
      :count => 255)], @file_model.errors[:file_file_name]
    assert_equal [error_message_from_model(@file_model, :file_content_type, :too_long,
      :count => 255)], @file_model.errors[:file_content_type]
  end
  
  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates file must have an extension' do
    @file_model.file = Rack::Test::UploadedFile.new(
      "#{self.class.fixture_path}/files/test", 'text/plain'
    )
    
    assert @file_model.invalid?
    assert_equal 1, @file_model.errors.count
    assert_equal [
      error_message_from_model(@file_model, :file, :without_extension)
    ], @file_model.errors[:file]
  end
end
