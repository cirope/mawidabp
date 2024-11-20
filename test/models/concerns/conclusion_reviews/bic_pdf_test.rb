require 'test_helper'

class ConclusionReviews::BicPdfTest < ActiveSupport::TestCase
  fixtures :conclusion_reviews, :findings

  setup do
    set_organization

    skip unless Current.conclusion_pdf_format == 'bic'

    @conclusion_review = ConclusionReview.find_by! id: conclusion_reviews(:conclusion_past_final_review).id
    @weaknesses        = @conclusion_review.review.weaknesses
    @original_states   = @weaknesses.map(&:state)
  end

  teardown do
    @weaknesses.each_with_index do |weakness, index|
      weakness.update_column :state, @original_states[index]
    end
  end

  test 'should exclude implemented audited findings' do
    @weaknesses.first.update_column :state, Finding::STATUS[:implemented_audited]

    @conclusion_review.exclude_implemented_audited_findings = true

    filtered_weaknesses = @conclusion_review.bic_exclude_findings @weaknesses

    assert_not_includes filtered_weaknesses.pluck(:state), Finding::STATUS[:implemented_audited]
  end

  test 'should exclude criteria mismatch findings' do
    @weaknesses.first.update_column :state, Finding::STATUS[:criteria_mismatch]

    @conclusion_review.exclude_criteria_mismatch_findings = true

    filtered_weaknesses = @conclusion_review.bic_exclude_findings @weaknesses

    assert_not_includes filtered_weaknesses.pluck(:state), Finding::STATUS[:criteria_mismatch]
  end

  test 'should exclude both implemented audited and criteria mismatch findings' do
    @weaknesses[0].update_column :state, Finding::STATUS[:implemented_audited]
    @weaknesses[1].update_column :state, Finding::STATUS[:criteria_mismatch]

    @conclusion_review.exclude_implemented_audited_findings = true
    @conclusion_review.exclude_criteria_mismatch_findings   = true

    filtered_weaknesses = @conclusion_review.bic_exclude_findings @weaknesses

    assert_not_includes filtered_weaknesses.pluck(:state), Finding::STATUS[:implemented_audited]
    assert_not_includes filtered_weaknesses.pluck(:state), Finding::STATUS[:criteria_mismatch]
  end

  test 'should not exclude any findings when both exclusions are false' do
    @conclusion_review.exclude_implemented_audited_findings = false
    @conclusion_review.exclude_criteria_mismatch_findings   = false

    filtered_weaknesses = @conclusion_review.bic_exclude_findings @weaknesses

    assert_equal filtered_weaknesses.pluck(:state), @weaknesses.pluck(:state)
  end

  test 'should generate PDF without errors' do
    Current.user = users :auditor

    assert_nothing_raised do
      @conclusion_review.bic_pdf Current.organization
    end

    pdf_path = @conclusion_review.absolute_pdf_path

    assert File.exist?(pdf_path)
    assert File.size(pdf_path) > 0

    FileUtils.rm pdf_path
  ensure
    Current.user = nil
  end
end
