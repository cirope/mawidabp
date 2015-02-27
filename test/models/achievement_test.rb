require 'test_helper'

class AchievementTest < ActiveSupport::TestCase
  def setup
    @achievement = achievements :productivity
  end

  test 'blank attributes' do
    @achievement.benefit = nil

    assert @achievement.invalid?
    assert_error @achievement, :benefit, :blank
  end

  test 'numeric attributes' do
    @achievement.amount = 'xxx'

    assert @achievement.invalid?
    assert_error @achievement, :amount, :not_a_number
  end

  test 'conditional blank attributes' do
    @achievement.amount = ''

    assert @achievement.invalid?
    assert_error @achievement, :amount, :blank

    @achievement = achievements :quality_of_service
    @achievement.comment = ''

    assert @achievement.invalid?
    assert_error @achievement, :comment, :blank
  end
end
