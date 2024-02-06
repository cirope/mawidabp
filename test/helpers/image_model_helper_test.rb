require 'test_helper'

class ImageModelHelperTest < ActionView::TestCase
  include FontAwesome::Sass::Rails::ViewHelpers

  setup do
    @image_model = image_models :image_one
  end

  test 'should return nil link to download image' do
    @image_model.image = nil
    template           = Object.new

    template.extend ActionView::Helpers::FormHelper
    template.extend ActionView::Helpers::FormOptionsHelper

    form_builder = SimpleForm::FormBuilder.new :control_objective, @image_model, template, {}

    assert_nil link_to_download_image(form_builder)
  end

  test 'should return nil link to download image when cached true' do
    @image_model.image = Rack::Test::UploadedFile.new TEST_IMAGE_FULL_PATH, 'png'
    template           = Object.new

    template.extend ActionView::Helpers::FormHelper
    template.extend ActionView::Helpers::FormOptionsHelper

    form_builder = SimpleForm::FormBuilder.new :control_objective, @image_model, template, {}

    assert_nil link_to_download_image(form_builder)
  end

  test 'should return link to download image' do
    uploaded_file      = Rack::Test::UploadedFile.new TEST_IMAGE_FULL_PATH, 'png'
    @image_model.image = uploaded_file

    @image_model.save!
    @image_model.reload

    template = Object.new

    template.extend ActionView::Helpers::FormHelper
    template.extend ActionView::Helpers::FormOptionsHelper

    form_builder = SimpleForm::FormBuilder.new :control_objective, @image_model, template, {}
    link_to      = link_to_download_image form_builder
    options      = {
      class: 'btn btn-outline-secondary',
      title: @image_model.identifier.titleize,
      data: { ignore_unsaved_data: true },
      id: "#{@image_model.class.name.underscore}_#{@image_model.object_id}"
    }

    expected = link_to @image_model.image.url, options do
      icon 'fas', 'download'
    end

    assert_equal link_to, expected
  end

  test 'should return blank link to remove image' do
    image_model = ImageModel.new
    template    = Object.new

    template.extend ActionView::Helpers::FormHelper
    template.extend ActionView::Helpers::FormOptionsHelper

    form_builder = SimpleForm::FormBuilder.new :control_objective, image_model, template, {}

    assert link_to_remove_image(form_builder).blank?
  end

  test 'should return link to remove image' do
    uploaded_file      = Rack::Test::UploadedFile.new TEST_IMAGE_FULL_PATH, 'png'
    @image_model.image = uploaded_file
    template           = Object.new

    template.extend ActionView::Helpers::FormHelper
    template.extend ActionView::Helpers::FormOptionsHelper

    form_builder = SimpleForm::FormBuilder.new :control_objective, @image_model, template, {}
    link_to      = link_to_remove_image form_builder
    expected     = ''

    expected << form_builder.hidden_field(
      :_destroy,
      class: 'destroy',
      value: 0,
      id: "remove_#{@image_model.class.name.underscore}_hidden_#{@image_model.object_id}"
    )

    expected << link_to(
      icon('fas', 'times-circle'), '#',
      title: t('label.delete'),
      class: 'ms-2',
      data: {
        'dynamic-target' => "##{@image_model.class.name.underscore}_#{@image_model.object_id}",
        'dynamic-form-event' => 'hideItembutton',
        'show-tooltip' => true
      }
    )

    assert_equal link_to, expected
  end
end
