require 'test_helper'

class WeaknessTemplateTest < ActiveSupport::TestCase
  setup do
    @weakness_template = weakness_templates :security
  end

  test 'blank attributes' do
    @weakness_template.title = ''
    @weakness_template.description = ''

    assert @weakness_template.invalid?
    assert_error @weakness_template, :title, :blank
    assert_error @weakness_template, :description, :blank
  end

  test 'unique attributes' do
    weakness_template = @weakness_template.dup

    assert weakness_template.invalid?
    assert_error weakness_template, :title, :taken
  end

  test 'validates attributes encoding' do
    @weakness_template.title = "\n\t"
    @weakness_template.description = "\n\t"

    assert @weakness_template.invalid?
    assert_error @weakness_template, :title, :pdf_encoding
    assert_error @weakness_template, :description, :pdf_encoding
  end
end
