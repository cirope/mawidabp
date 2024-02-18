require 'test_helper'

# Clase para probar el modelo "FileModel"
class FileModelTest < ActiveSupport::TestCase
  fixtures :file_models

  # Función para inicializar las variables utilizadas en las pruebas
  setup do
    @file_model = FileModel.find file_models(:text_file).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of FileModel, @file_model
    assert_equal file_models(:text_file).file_file_name, @file_model.file_file_name
    assert_equal file_models(:text_file).file_content_type, @file_model.file_content_type
    assert_equal file_models(:text_file).file_file_size, @file_model.file_file_size
  end

  # Prueba la creación de un modelo de archivo
  test 'create' do
    assert_difference 'FileModel.count' do
      file = Rack::Test::UploadedFile.new(
        "#{self.class.fixture_paths.first}files/test.txt", 'text/plain'
      )

      new_file_model      = FileModel.new
      new_file_model.file = file

      new_file_model.save!

      assert new_file_model.file_file_name, 'test.txt'
      assert new_file_model.file_content_type, 'text/plain'
      assert_equal File.size(new_file_model.file.path), new_file_model.file_file_size
      assert Dir.exist?(new_file_model.file.store_dir)
      assert File.exist?(new_file_model.file.path)
    end
  end

  # Prueba de actualización de un modelo de archivo
  test 'update and delete file' do
    file = Rack::Test::UploadedFile.new(
      "#{self.class.fixture_paths.first}files/test.pdf", 'application/pdf'
    )

    assert @file_model.update(file: file)

    @file_model.reload

    assert @file_model.file_file_name, 'test.pdf'
    assert @file_model.file_content_type, 'application/pdf'
    assert_equal File.size(@file_model.file.path), @file_model.file_file_size
    assert Dir.exist?(@file_model.file.store_dir)
    assert File.exist?(@file_model.file.path)

    @file_model.file.remove!

    @file_model.reload

    refute @file_model.file?
    refute Dir.exist?(@file_model.file.store_dir)

    parent_dir = File.dirname @file_model.file.store_dir

    refute Dir.exist?(parent_dir)
  end

  # Prueba de eliminación de un modelo de archivo
  test 'destroy' do
    assert_difference 'FileModel.count', -1 do
      @file_model.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates lenght attributes' do
    @file_model.file_file_name    = "#{'abc' * 100}.txt"
    @file_model.file_content_type = 'abc' * 100

    assert @file_model.invalid?
    assert_error @file_model, :file_file_name, :too_long, count: 255
    assert_error @file_model, :file_content_type, :too_long, count: 255
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates file must have an extension' do
    @file_model.file = Rack::Test::UploadedFile.new(
      "#{self.class.fixture_paths.first}/files/test", 'text/plain'
    )

    assert @file_model.invalid?
    assert_error @file_model, :file, :without_extension
  end

  test 'validates file extension constraints' do
    @file_model.file = Rack::Test::UploadedFile.new(
      "#{self.class.fixture_paths.first}/files/test.csv", 'text/plain'
    )

    if @file_model.file.extension_allowlist.present?
      assert @file_model.invalid?
      assert_error @file_model, :file, :extension_allowlist_error,
        extension: "\"csv\"", allowed_types: @file_model.file.extension_allowlist.join(', ')
    end
  end
end
