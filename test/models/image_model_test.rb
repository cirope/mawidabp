require 'test_helper'

class ImageModelTest < ActiveSupport::TestCase
  fixtures :image_models

  setup do
    @image_model = image_models :image_one
  end

  test 'create ImageModel, update and delete image' do
    assert_difference 'ImageModel.count' do
      new_image_model = create_image_model

      assert new_image_model.image?
      assert new_image_model.image_file_name, 'test.gif'
      assert_equal 'image/gif', new_image_model.image_content_type
      assert_equal File.size(new_image_model.image.path), new_image_model.image_file_size

      assert_image_paths new_image_model

      image = Rack::Test::UploadedFile.new(
        "#{Rails.root}/test/fixtures/files/test.jpg", 'image/jpeg', true
      )

      new_image_model.image = image

      new_image_model.save!
      new_image_model.image.recreate_versions!

      new_image_model.reload

      assert new_image_model.image?
      assert new_image_model.image_file_name, 'test.jpg'
      assert_equal 'image/jpeg', new_image_model.image_content_type
      assert_equal File.size(new_image_model.image.path), new_image_model.image_file_size

      assert_image_paths new_image_model

      new_image_model.image.remove!

      new_image_model.reload

      refute new_image_model.image?

      refute Dir.exist?(new_image_model.image.store_dir)

      parent_dir = File.dirname new_image_model.image.store_dir

      refute Dir.exist?(parent_dir)
    end
  end

  test 'destroy' do
    assert_difference 'ImageModel.count', -1 do
      Organization.where(image_model_id: @image_model.id).update_all image_model_id: nil

      @image_model.destroy
    end
  end

  test 'validates lenght attributes' do
    @image_model.image_file_name    = 'abc' * 100
    @image_model.image_content_type = "image/#{'abc' * 100}"

    assert @image_model.invalid?
    assert_error @image_model, :image_file_name, :too_long, count: 255
    assert_error @image_model, :image_content_type, :too_long, count: 255
  end

  test 'image geometry for original version' do
    new_image_model     = create_image_model
    dimensions_expected = {}

    MiniMagick::Image.open(new_image_model.image.path)[:dimensions].tap do |dimension|
      dimensions_expected.merge! width: dimension.first, height: dimension.last
    end

    assert_equal dimensions_expected, new_image_model.image_geometry
  end

  test 'image geometry for medium version' do
    new_image_model     = create_image_model
    dimensions_expected = {}

    MiniMagick::Image.open(new_image_model.image.medium.path)[:dimensions].tap do |dimension|
      dimensions_expected.merge! width: dimension.first, height: dimension.last
    end

    assert_equal dimensions_expected, new_image_model.image_geometry(:medium)
  end

  test 'image geometry for small version' do
    new_image_model     = create_image_model
    dimensions_expected = {}

    MiniMagick::Image.open(new_image_model.image.small.path)[:dimensions].tap do |dimension|
      dimensions_expected.merge! width: dimension.first, height: dimension.last
    end

    assert_equal dimensions_expected, new_image_model.image_geometry(:small)
  end

  test 'image geometry for thumb version' do
    new_image_model     = create_image_model
    dimensions_expected = {}

    MiniMagick::Image.open(new_image_model.image.thumb.path)[:dimensions].tap do |dimension|
      dimensions_expected.merge! width: dimension.first, height: dimension.last
    end

    assert_equal dimensions_expected, new_image_model.image_geometry(:thumb)
  end

  test 'image geometry for pdf_thumb version' do
    new_image_model     = create_image_model
    dimensions_expected = {}

    MiniMagick::Image.open(new_image_model.image.pdf_thumb.path)[:dimensions].tap do |dimension|
      dimensions_expected.merge! width: dimension.first, height: dimension.last
    end

    assert_equal dimensions_expected, new_image_model.image_geometry(:pdf_thumb)
  end

  test 'image size for original version' do
    new_image_model = create_image_model
    dimensions      = {}

    MiniMagick::Image.open(new_image_model.image.path)[:dimensions].tap do |dimension|
      dimensions.merge! width: dimension.first, height: dimension.last
    end

    assert_equal "#{dimensions[:width]}x#{dimensions[:height]}", new_image_model.image_size
  end

  test 'image size for medium version' do
    new_image_model = create_image_model
    dimensions      = {}

    MiniMagick::Image.open(new_image_model.image.medium.path)[:dimensions].tap do |dimension|
      dimensions.merge! width: dimension.first, height: dimension.last
    end

    assert_equal "#{dimensions[:width]}x#{dimensions[:height]}", new_image_model.image_size(:medium)
  end

  test 'image size for small version' do
    new_image_model = create_image_model
    dimensions      = {}

    MiniMagick::Image.open(new_image_model.image.small.path)[:dimensions].tap do |dimension|
      dimensions.merge! width: dimension.first, height: dimension.last
    end

    assert_equal "#{dimensions[:width]}x#{dimensions[:height]}", new_image_model.image_size(:small)
  end

  test 'image size for thumb version' do
    new_image_model = create_image_model
    dimensions      = {}

    MiniMagick::Image.open(new_image_model.image.thumb.path)[:dimensions].tap do |dimension|
      dimensions.merge! width: dimension.first, height: dimension.last
    end

    assert_equal "#{dimensions[:width]}x#{dimensions[:height]}", new_image_model.image_size(:thumb)
  end

  test 'image size for pdf_thumb version' do
    new_image_model = create_image_model
    dimensions      = {}

    MiniMagick::Image.open(new_image_model.image.pdf_thumb.path)[:dimensions].tap do |dimension|
      dimensions.merge! width: dimension.first, height: dimension.last
    end

    assert_equal "#{dimensions[:width]}x#{dimensions[:height]}", new_image_model.image_size(:pdf_thumb)
  end

  private

    def create_image_model
      image = Rack::Test::UploadedFile.new(
        "#{Rails.root}/test/fixtures/files/test.gif", 'image/gif', true
      )

      ImageModel.create! imageable: organizations(:cirope),
                         image: image
    end

    def assert_image_paths image_model
      assert File.exist?(image_model.image.path)
      assert File.exist?(image_model.image.medium.path)
      assert File.exist?(image_model.image.small.path)
      assert File.exist?(image_model.image.thumb.path)
      assert File.exist?(image_model.image.pdf_thumb.path)
      assert Dir.exist?(image_model.image.store_dir)
    end
end
