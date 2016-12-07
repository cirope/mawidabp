require 'test_helper'

class ImageModelTest < ActiveSupport::TestCase
  fixtures :image_models

  def setup
    @image_model = image_models :image_one
  end

  test 'create' do
    assert_difference 'ImageModel.count' do
      @image_model = ImageModel.create!(
        imageable: organizations(:cirope),
        image: Rack::Test::UploadedFile.new(
          "#{Rails.root}/test/fixtures/files/test.gif", 'image/gif', true
        )
      )
    end

    assert_equal 'image/gif', @image_model.reload.image_content_type
    assert_equal File.size(@image_model.image.path), @image_model.image_file_size
  end

  test 'update' do
    assert_not_equal 'image/gif', @image_model.image_content_type

    assert @image_model.update(
      image: Rack::Test::UploadedFile.new(
        "#{Rails.root}/test/fixtures/files/test.gif", 'image/gif', true
      )
    ), @image_model.errors.full_messages.join('; ')

    assert_equal 'image/gif', @image_model.reload.image_content_type
  end

  test 'delete' do
    assert_difference('ImageModel.count', -1) do
      Organization.where(image_model_id: @image_model.id).update_all image_model_id: nil

      @image_model.destroy
    end
  end

  test 'validates lenght attributes' do
    @image_model.image_file_name = 'abc' * 100
    @image_model.image_content_type = "image/#{'abc' * 100}"

    assert @image_model.invalid?
    assert_error @image_model, :image_file_name, :too_long, count: 255
    assert_error @image_model, :image_content_type, :too_long, count: 255
  end
end
