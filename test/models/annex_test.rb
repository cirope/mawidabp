require 'test_helper'

class PlanTest < ActiveSupport::TestCase
  setup do
    @annex = annexes :annex_one
  end

  test 'invalid without title' do
    @annex.title = nil

    refute @annex.valid?

    assert_error @annex, :title, :blank
  end

  test 'invalid without description and images' do
    @annex.description = nil

    refute @annex.valid?

    assert_error @annex, :description, :blank
    assert_error @annex, :image_models, :blank
  end

  test 'valid with description without images' do
    assert @annex.valid?
  end

  test 'valid without description with image' do
    @annex.description = nil

    @annex.image_models << image_models(:image_one)

    assert @annex.valid?
  end
end
