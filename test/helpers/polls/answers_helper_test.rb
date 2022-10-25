require 'test_helper'

class Polls::AnswersHelperTest < ActionView::TestCase
  include FontAwesome::Sass::Rails::ViewHelpers

  setup do
    @answer = answers :answer_yes_no
  end

  test 'should return nil link to download attached file' do
    template = Object.new

    template.extend ActionView::Helpers::FormHelper
    template.extend ActionView::Helpers::FormOptionsHelper

    form_builder = SimpleForm::FormBuilder.new :answer, @answer, template, {}

    assert_nil link_to_download_attached_file(form_builder)
  end

  test 'should return nil link to download attached file when cached true' do
    @answer.attached = Rack::Test::UploadedFile.new TEST_IMAGE_FULL_PATH, 'png'
    template         = Object.new

    template.extend ActionView::Helpers::FormHelper
    template.extend ActionView::Helpers::FormOptionsHelper

    form_builder = SimpleForm::FormBuilder.new :answer, @answer, template, {}

    assert_nil link_to_download_attached_file(form_builder)
  end

  test 'should return link to download attached file' do
    uploaded_file    = Rack::Test::UploadedFile.new TEST_IMAGE_FULL_PATH, 'png'
    @answer.attached = uploaded_file

    @answer.save!
    @answer.reload

    template = Object.new

    template.extend ActionView::Helpers::FormHelper
    template.extend ActionView::Helpers::FormOptionsHelper

    form_builder = SimpleForm::FormBuilder.new :answer, @answer, template, {}
    link_to      = link_to_download_attached_file form_builder
    options      = {
      class: 'btn btn-outline-secondary mb-3',
      title: @answer.attached.identifier.titleize,
      data: { ignore_unsaved_data: true },
      id: "answer_attached_#{@answer.object_id}"
    }

    expected = link_to @answer.attached.url, options do
      icon 'fas', 'download'
    end

    assert_equal link_to, expected
  end

  test 'should return blank link to remove attached file' do
    template = Object.new

    template.extend ActionView::Helpers::FormHelper
    template.extend ActionView::Helpers::FormOptionsHelper

    form_builder = SimpleForm::FormBuilder.new :answer, @answer, template, {}

    assert link_to_remove_attached_file(form_builder).blank?
  end

  test 'should return link to remove attached file' do
    uploaded_file    = Rack::Test::UploadedFile.new TEST_IMAGE_FULL_PATH, 'png'
    @answer.attached = uploaded_file
    template         = Object.new

    template.extend ActionView::Helpers::FormHelper
    template.extend ActionView::Helpers::FormOptionsHelper

    form_builder = SimpleForm::FormBuilder.new :answer, @answer, template, {}
    link_to      = link_to_remove_attached_file form_builder
    expected     = ''

    expected << form_builder.hidden_field(
      :remove_attached,
      class: 'destroy',
      value: 0,
      id: "remove_attached_hidden_#{@answer.object_id}"
    )

    expected << link_to(
      icon('fas', 'times-circle'), '#',
      title: t('label.delete'),
      data: {
        'dynamic-target' => "#answer_attached_#{@answer.object_id}",
        'dynamic-form-event' => 'hideItembutton',
        'show-tooltip' => true
      }
    )

    assert_equal link_to, expected
  end
end
