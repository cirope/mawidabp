require 'test_helper'

class BestPractices::ControlObjectivesHelperTest < ActionView::TestCase
  include FontAwesome::Sass::Rails::ViewHelpers

  setup do
    @control_objective = control_objectives :impact_analysis
  end

  test 'should return nil link to download support file' do
    template = Object.new

    template.extend ActionView::Helpers::FormHelper
    template.extend ActionView::Helpers::FormOptionsHelper

    form_builder = SimpleForm::FormBuilder.new :control_objective, @control_objective, template, {}

    assert_nil link_to_download_support_file(form_builder)
  end

  test 'should return nil link to download support file when cached true' do
    @control_objective.support = Rack::Test::UploadedFile.new TEST_IMAGE_FULL_PATH, 'png'
    template                   = Object.new

    template.extend ActionView::Helpers::FormHelper
    template.extend ActionView::Helpers::FormOptionsHelper

    form_builder = SimpleForm::FormBuilder.new :control_objective, @control_objective, template, {}

    assert_nil link_to_download_support_file(form_builder)
  end

  test 'should return link to download support file' do
    uploaded_file              = Rack::Test::UploadedFile.new TEST_IMAGE_FULL_PATH, 'png'
    @control_objective.support = uploaded_file

    @control_objective.save!
    @control_objective.reload

    template = Object.new

    template.extend ActionView::Helpers::FormHelper
    template.extend ActionView::Helpers::FormOptionsHelper

    form_builder = SimpleForm::FormBuilder.new :control_objective, @control_objective, template, {}
    link_to      = link_to_download_support_file form_builder
    options      = {
      class: 'btn btn-outline-secondary mb-3',
      title: @control_objective.support.identifier.titleize,
      data: { ignore_unsaved_data: true },
      id: "control_objective_support_#{@control_objective.object_id}"
    }

    expected = link_to @control_objective.support.url, options do
      icon 'fas', 'download'
    end

    assert_equal link_to, expected
  end

  test 'should return blank link to remove support file' do
    template = Object.new

    template.extend ActionView::Helpers::FormHelper
    template.extend ActionView::Helpers::FormOptionsHelper

    form_builder = SimpleForm::FormBuilder.new :control_objective, @control_objective, template, {}

    assert link_to_remove_support_file(form_builder).blank?
  end

  test 'should return link to remove support file' do
    uploaded_file              = Rack::Test::UploadedFile.new TEST_IMAGE_FULL_PATH, 'png'
    @control_objective.support = uploaded_file
    template                   = Object.new

    template.extend ActionView::Helpers::FormHelper
    template.extend ActionView::Helpers::FormOptionsHelper

    form_builder = SimpleForm::FormBuilder.new :control_objective, @control_objective, template, {}
    link_to      = link_to_remove_support_file form_builder
    expected     = ''

    expected << form_builder.hidden_field(
      :remove_support,
      class: 'destroy',
      value: 0,
      id: "remove_support_hidden_#{@control_objective.object_id}"
    )

    expected << link_to(
      icon('fas', 'times-circle'), '#',
      title: t('label.delete'),
      data: {
        'dynamic-target' => "#control_objective_support_#{@control_objective.object_id}",
        'dynamic-form-event' => 'hideItembutton',
        'show-tooltip' => true
      }
    )

    assert_equal link_to, expected
  end
end
