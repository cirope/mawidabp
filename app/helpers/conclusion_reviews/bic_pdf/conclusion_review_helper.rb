module ConclusionReviews::BicPdf::ConclusionReviewHelper
  def bic_review_auditors_text conclusion_review
    supervisors = conclusion_review.review.review_user_assignments.select &:supervisor?
    auditors    = conclusion_review.review.review_user_assignments.select &:auditor?

    (supervisors | auditors).map(&:user).map(&:full_name).join '; '
  end

  def bic_review_owners_text conclusion_review
    assignments = conclusion_review.review.review_user_assignments.select &:audited?
    assignments = assignments.select &:owner if assignments.select(&:owner).any?
    names       = assignments.map(&:user).map do |u|
      u.full_name_with_function conclusion_review.issue_date
    end

    names.join '; '
  end

  def review_version_text draft
    I18n.t "conclusion_review.bic.cover.versions.#{draft ? 'draft' : 'final'}"
  end

  def put_bic_cover_note_on conclusion_review
    note = if conclusion_review.draft? && conclusion_review.review.weaknesses.any?
             'draft_with_weaknesses'
           elsif !conclusion_review.draft? && conclusion_review.review.weaknesses.any?
             'final_with_weaknesses'
           elsif !conclusion_review.draft?
             'final_without_weaknesses'
           end

    note.present? ? I18n.t("conclusion_review.bic.cover.#{note}") : ''
  end

  def bic_previous_review_text conclusion_review
    if conclusion_review.previous_identification.present? && conclusion_review.previous_date.present?
      [
        conclusion_review.previous_identification,
        "(#{I18n.l conclusion_review.previous_date})"
      ].join ' '
    elsif conclusion_review.previous_identification.present?
      conclusion_review.previous_identification
    elsif previous = conclusion_review.review.previous
      [
        previous.identification,
        "(#{I18n.l previous.conclusion_final_review.issue_date})"
      ].join ' '
    else
      '-'
    end
  end

  def bic_review_period conclusion_review
    plan_item_start = I18n.l conclusion_review.plan_item.start, format: :minimal
    plan_item_end   = I18n.l conclusion_review.plan_item.end, format: :minimal

    I18n.t 'conclusion_review.bic.cover.review_period_description',
           plan_item_start: plan_item_start,
           plan_item_end: plan_item_end
  end

  def bic_weakness_responsible weakness
    assignments = weakness.finding_user_assignments.select do |fua|
      fua.user.can_act_as_audited?
    end

    if assignments.select(&:process_owner).any?
      assignments = assignments.select &:process_owner
    end

    assignments.map(&:user).map do |u|
      u.full_name_with_function weakness.review.issue_date
    end.join '; '
  end

  def conclusion_review_weaknesses conclusion_review
    weaknesses = if conclusion_review.draft?
                   conclusion_review.review.weaknesses
                 else
                   conclusion_review.review.final_weaknesses
                 end

    conclusion_review.bic_exclude_regularized_findings weaknesses
  end

  def watermark_class draft
    draft ? 'watermark-bic' : ''
  end

  def follow_up_date_weakness weakness
    weakness.follow_up_date ? I18n.l(weakness.follow_up_date) : '-'
  end

  def risk_style weakness
    weakness.implemented_audited? ? 'text-green' : 'text-white'
  end

  def conclusion_padding conclusion_review
    if !conclusion_review.reference.present?
      'pt-15'
    end
  end
end
