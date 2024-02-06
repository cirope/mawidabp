require 'test_helper'

class ConclusionReviews::BicPdf::ConclusionReviewHelperTest < ActionView::TestCase
  test 'get bic review auditors text' do
    conclusion_review = conclusion_reviews :conclusion_current_final_review
    supervisors       = conclusion_review.review.review_user_assignments.select &:supervisor?
    auditors          = conclusion_review.review.review_user_assignments.select &:auditor?
    result            = (supervisors | auditors).map(&:user).map(&:full_name).join '; '

    assert_equal result, bic_review_auditors_text(conclusion_review)
  end

  test 'get bic review owners text' do
    conclusion_review = conclusion_reviews :conclusion_current_final_review
    assignments       = conclusion_review.review.review_user_assignments.select &:audited?
    assignments       = assignments.select &:owner if assignments.select(&:owner).any?

    names = assignments.map(&:user).map do |u|
      u.full_name_with_function conclusion_review.issue_date
    end

    result = names.join '; '

    assert_equal result, bic_review_owners_text(conclusion_review)
  end

  test 'get review version text when is draft' do
    assert_equal I18n.t('conclusion_review.bic.cover.versions.draft'), review_version_text(true)
  end

  test 'get review version text when is not draft' do
    assert_equal I18n.t('conclusion_review.bic.cover.versions.final'), review_version_text(false)
  end

  test 'get put bic cover note on when is draft and dont have weaknesses' do
    review_without_weaknesses      = reviews :review_without_conclusion_and_without_findings
    conclusion_draft_review        = conclusion_reviews :conclusion_current_draft_review
    conclusion_draft_review.review = review_without_weaknesses

    assert_equal '', put_bic_cover_note_on(conclusion_draft_review)
  end

  test 'get put bic cover note on when is draft and have weaknesses' do
    conclusion_draft_review_with_weaknesses =
      conclusion_reviews :conclusion_current_draft_review

    assert_equal I18n.t('conclusion_review.bic.cover.draft_with_weaknesses'),
                 put_bic_cover_note_on(conclusion_draft_review_with_weaknesses)
  end

  test 'get put bic cover note on when is final and dont have weaknesses' do
    review_without_weaknesses      = reviews :review_without_conclusion_and_without_findings
    conclusion_draft_review        = conclusion_reviews :conclusion_current_final_review
    conclusion_draft_review.review = review_without_weaknesses

    assert_equal I18n.t('conclusion_review.bic.cover.final_without_weaknesses'),
                 put_bic_cover_note_on(conclusion_draft_review)
  end

  test 'get put bic cover note on when is final and have weaknesses' do
    conclusion_draft_review_with_weaknesses =
      conclusion_reviews :conclusion_current_final_review

    assert_equal I18n.t('conclusion_review.bic.cover.final_with_weaknesses'),
                 put_bic_cover_note_on(conclusion_draft_review_with_weaknesses)
  end

  test 'get bic previous review text when have previous identenfication and previous date' do
    conclusion_review                         = conclusion_reviews :conclusion_current_final_review
    conclusion_review.previous_identification = 'prev'
    conclusion_review.previous_date           = Date.new

    result = [
      conclusion_review.previous_identification,
      "(#{I18n.l conclusion_review.previous_date})"
    ].join ' '

    assert_equal result, bic_previous_review_text(conclusion_review)
  end

  test 'get bic previous review text when have previous identenfication' do
    conclusion_review                         = conclusion_reviews :conclusion_current_final_review
    conclusion_review.previous_identification = 'prev'

    assert_equal conclusion_review.previous_identification, bic_previous_review_text(conclusion_review)
  end

  test 'get bic previous review text when have previous' do
    Current.organization = organizations :cirope
    Current.user         = users :supervisor

    Current.user.business_unit_types << business_unit_types(:cycle)

    conclusion_review = conclusion_reviews :conclusion_current_final_review

    result = [
      conclusion_review.review.previous.identification,
      "(#{I18n.l conclusion_review.review.previous.conclusion_final_review.issue_date})"
    ].join ' '

    assert_equal result, bic_previous_review_text(conclusion_review)
  end

  test 'get bic previous review text when dont have any previous' do
    Current.user      = users :supervisor
    conclusion_review = conclusion_reviews :conclusion_current_final_review

    assert_equal '-', bic_previous_review_text(conclusion_review)
  end

  test 'get bic review period' do
    conclusion_review = conclusion_reviews :conclusion_current_final_review
    plan_item_start   = I18n.l conclusion_review.plan_item.start, format: :minimal
    plan_item_end     = I18n.l conclusion_review.plan_item.end, format: :minimal

    result = I18n.t 'conclusion_review.bic.cover.review_period_description',
                    plan_item_start: plan_item_start,
                    plan_item_end: plan_item_end

    assert_equal result, bic_review_period(conclusion_review)
  end

  test 'get bic weakness responsible when dont have process owner' do
    finding_user_assignment               = finding_user_assignments :being_implemented_weakness_audited
    finding_user_assignment.process_owner = false

    finding_user_assignment.save!

    weakness = findings :being_implemented_weakness

    assignments = weakness.finding_user_assignments.select do |fua|
      fua.user.can_act_as_audited?
    end

    result = assignments.map(&:user).map do |u|
      u.full_name_with_function weakness.review.issue_date
    end.join '; '

    assert_equal result, bic_weakness_responsible(weakness)
  end

  test 'get bic weakness responsible when have any process owner' do
    weakness = findings :being_implemented_weakness

    assignments = weakness.finding_user_assignments.select do |fua|
      fua.user.can_act_as_audited?
    end

    assignments = assignments.select &:process_owner

    result = assignments.map(&:user).map do |u|
      u.full_name_with_function weakness.review.issue_date
    end.join '; '

    assert_equal result, bic_weakness_responsible(weakness)
  end

  test 'get conclusion review weaknesses when is final' do
    conclusion_review = conclusion_reviews :conclusion_current_final_review

    assert_equal conclusion_review.bic_exclude_regularized_findings(conclusion_review.review.final_weaknesses),
                 conclusion_review_weaknesses(conclusion_review)
  end

  test 'get conclusion review weaknesses when is draft' do
    conclusion_review = conclusion_reviews :conclusion_current_draft_review

    assert_equal conclusion_review.bic_exclude_regularized_findings(conclusion_review.review.weaknesses),
                 conclusion_review_weaknesses(conclusion_review)
  end

  test 'get watermark class when is draft' do
    assert_equal 'watermark-bic', watermark_class(true)
  end

  test 'get watermark class when is not draft' do
    assert_equal '', watermark_class(false)
  end

  test 'get follow up date weakness have follow up date' do
    weakness = findings :being_implemented_weakness

    assert_equal I18n.l(weakness.follow_up_date), follow_up_date_weakness(weakness)
  end

  test 'get follow up date weakness dont have follow up date' do
    assert_equal '-', follow_up_date_weakness(findings(:unconfirmed_for_notification_weakness))
  end

  test 'get risk style when is implemented_audited' do
    weakness       = findings :being_implemented_weakness
    weakness.state = Finding::STATUS[:implemented_audited]

    assert_equal 'text-green', risk_style(weakness)
  end

  test 'get risk style when is not implemented_audited' do
    assert_equal 'text-white', risk_style(findings(:being_implemented_weakness))
  end
end
