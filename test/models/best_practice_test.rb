require 'test_helper'

class BestPracticeTest < ActiveSupport::TestCase

  def setup
    @best_practice = best_practices :iso_27001

    set_organization
  end

  test 'create' do
    assert_difference 'BestPractice.count' do
      @best_practice = BestPractice.list.create(
        name: 'New name', description: 'New description'
      )
    end

    assert_equal organizations(:cirope).id,
      @best_practice.organization_id
  end

  test 'update' do
    assert @best_practice.update(name: 'Updated name'),
      @best_practice.errors.full_messages.join('; ')

    assert_equal 'Updated name', @best_practice.reload.name
  end

  test 'destroy' do
    assert_difference 'BestPractice.count', -1 do
      best_practices(:useless_best_practice).destroy
    end
  end

  test 'destroy with asociated control objectives' do
    assert_no_difference 'BestPractice.count' do
      @best_practice.destroy
    end

    assert_equal 1, @best_practice.errors.size
  end

  test 'validates blank atrtributes' do
    @best_practice = BestPractice.new name: ''

    assert @best_practice.invalid?
    assert_error @best_practice, :name, :blank
    assert_error @best_practice, :organization_id, :blank
  end

  test 'validates length of attributes' do
    @best_practice.name = 'abcdd' * 52

    assert @best_practice.invalid?
    assert_error @best_practice, :name, :too_long, count: 255
  end

  test 'validates formated attributes' do
    @best_practice.organization_id = 'a'

    assert @best_practice.invalid?
    assert_error @best_practice, :organization_id, :not_a_number
  end

  test 'validates duplicated attributes' do
    @best_practice.name = best_practices(:bcra_A4609).name

    assert @best_practice.invalid?
    assert_error @best_practice, :name, :taken
  end
end
