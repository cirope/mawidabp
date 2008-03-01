require 'test_helper'

# Clase para probar el modelo "ImageModel"
class ImageModelTest < ActiveSupport::TestCase
  fixtures :image_models

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @image_model = ImageModel.find image_models(:image_one).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of ImageModel, @image_model
    assert_equal image_models(:image_one).filename, @image_model.filename
    assert_equal image_models(:image_one).content_type,
      @image_model.content_type
    assert_equal image_models(:image_one).size, @image_model.size
  end

  # Prueba la creación de un modelo de archivo
  test 'create' do
    assert_difference 'ImageModel.count' do
      @image_model = ImageModel.create(
        :filename => 'new_file.jpg',
        :content_type => 'image/gif',
        :size => 2000
      )
    end
  end

  # Prueba de actualización de un modelo de archivo
  test 'update' do
    assert @image_model.update_attributes(:filename => 'updated_name'),
      @image_model.errors.full_messages.join('; ')
    @image_model.reload
    assert_equal 'updated_name', @image_model.filename
  end

  # Prueba de eliminación de un modelo de archivo
  test 'delete' do
    assert_difference('ImageModel.count', -2) { @image_model.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validation' do
    @image_model = ImageModel.new(:uploaded_data =>
        ActionController::TestUploadedFile.new(make_file(1), 'image/gif'))

    assert @image_model.valid?, @image_model.errors.full_messages.join(' ;')

    FileUtils.rm_rf File.join("#{TEMP_PATH}image_model_test"), :secure => true

    @image_model = ImageModel.new(:uploaded_data =>
        ActionController::TestUploadedFile.new(make_file(21), 'image/gif'))

    assert @image_model.invalid?
    assert_equal error_message_from_model(@image_model, :size, :inclusion),
      @image_model.errors.on(:size)

    FileUtils.rm_rf File.join("#{TEMP_PATH}image_model_test"), :secure => true
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates lenght attributes' do
    @image_model.filename = 'abc' * 100
    @image_model.thumbnail = 'abc' * 100
    @image_model.content_type = 'abc' * 100
    assert @image_model.invalid?
    assert_equal 4, @image_model.errors.count
    assert_equal error_message_from_model(@image_model, :filename, :too_long,
      :count => 255), @image_model.errors.on(:filename)
    assert_equal error_message_from_model(@image_model, :thumbnail, :too_long,
      :count => 255), @image_model.errors.on(:thumbnail)
    assert_equal [error_message_from_model(@image_model, :content_type,
      :too_long, :count => 255), error_message_from_model(@image_model,
      :content_type, :inclusion)].sort,
    @image_model.errors.on(:content_type).sort
  end

  private

  def make_file(size_in_mb)
    file_path = File.join "#{TEMP_PATH}image_model_test",
      "test#{rand(1000)}.gif"

    FileUtils.makedirs "#{TEMP_PATH}image_model_test"

    File.open file_path, 'w' do |out|
      File.open(File.join(PUBLIC_PATH, 'images', 'mail.gif')) do |file|
        out << file.read
      end
      
      (size_in_mb * 1024).times { out << "#{'x' * 1023}\n" }
    end

    file_path
  end
end