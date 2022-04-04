require 'test_helper'

class MemosHelperTest < ActionView::TestCase
  test 'Should return group by business_unit in plan item unused' do
    business_unit                      = business_units :business_unit_three
    plan_item_without_id               = plan_items :current_plan_item_4_without_business_unit
    plan_item_without_id.business_unit = business_unit
    plan_item_without_id.project       = 'Test project'

    plan_item_without_id.save!

    @memo        = memos :first_memo
    Current.user = users :administrator
    template     = Object.new

    template.extend ActionView::Helpers::FormHelper
    template.extend ActionView::Helpers::FormOptionsHelper

    form_builder = SimpleForm::FormBuilder.new :memo, @memo, template, {}
    response     = memo_plan_item_field form_builder

    assert_match business_unit.business_unit_type.to_s, response
    assert_match 'Test project', response
  end

  test 'Should return file model memos' do
    memo = memos :first_memo

    out = '<ul>'

    memo.file_model_memos.each do |fm_m|
      link_for_download_attachment = link_to(
        fm_m.file_model.file_file_name, fm_m.file_model.file.url
      )

      out << "<li>#{link_for_download_attachment}</li>"
    end

    out << '</ul>'

    assert_equal out, show_file_model_memos(memo)
  end

  test 'Should return required by options' do
    expected = Memo::REQUIRED_BY_OPTIONS.map do |option|
      [option, option]
    end

    assert_equal expected, required_by_options
  end
end
