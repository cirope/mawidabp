require 'test_helper'

class WeaknessesHelperTest < ActionView::TestCase
  setup do
    set_organization
  end

  test 'should not disabled submit form when bic prefix' do
    skip unless %w(bic).include? Current.conclusion_pdf_format

    refute disabled_submit_form(false)
  end

  test 'should not disabled submit form when frozen is false' do
    skip if %w(bic).include? Current.conclusion_pdf_format

    frozen = false

    refute disabled_submit_form(frozen)
  end

  test 'should disabled submit form when frozen' do
    skip if %w(bic).include? Current.conclusion_pdf_format

    frozen = true

    assert disabled_submit_form(frozen)
  end
end
