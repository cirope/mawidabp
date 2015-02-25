require 'test_helper'

class BenefitTest < ActiveSupport::TestCase
  def setup
    @benefit = benefits :productivity
  end

  test 'blank attributes' do
    @benefit.name = ''
    @benefit.kind = ''

    assert @benefit.invalid?
    assert_error @benefit, :name, :blank
    assert_error @benefit, :kind, :blank
  end

  test 'included attributes' do
    @benefit.kind = 'wrong'

    assert @benefit.invalid?
    assert_error @benefit, :kind, :inclusion
  end
end
