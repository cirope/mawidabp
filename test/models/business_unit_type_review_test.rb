require 'test_helper'

class BusinessUnitTypeReviewTest < ActiveSupport::TestCase
  setup do
    @business_unit_type_review = business_unit_type_reviews :current_review_cycle_relation
  end

  test 'blank attributes' do
    @business_unit_type_review.review_id = nil
    @business_unit_type_review.business_unit_type_id = nil

    assert @business_unit_type_review.invalid?
    assert_error @business_unit_type_review, :review, :blank
    assert_error @business_unit_type_review, :business_unit_type, :blank
  end

  test 'unique attributes' do
    business_unit_type_review = @business_unit_type_review.dup

    assert business_unit_type_review.invalid?
    assert_error business_unit_type_review, :business_unit_type_id, :taken
  end
end
