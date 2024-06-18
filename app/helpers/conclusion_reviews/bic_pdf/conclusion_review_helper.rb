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

  def bic_internal_audit_review_dates conclusion_review
    start_date = bic_internal_audit_review_start_date conclusion_review
    end_date   = bic_internal_audit_review_end_date conclusion_review

    I18n.t 'conclusion_review.bic.cover.internal_audit_review_dates',
      start_date: start_date,
      end_date: end_date
  end

  def bic_internal_audit_review_start_date conclusion_review
    date = conclusion_review.review.opening_interview&.start_date

    date ? I18n.l(date, format: :minimal) : '--/--/--'
  end

  def bic_internal_audit_review_end_date conclusion_review
    I18n.l conclusion_review.issue_date, format: :minimal
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

  def short_bic_weakness_review_code review_code
    prefix = I18n.t('code_prefixes.weaknesses')

    review_code.sub(/^#{prefix}/, '').to_i
  end

  def sort_bic_weaknesses_by_risk? conclusion_review
    CONCLUSION_REVIEW_SORT_BY_RISK_START && conclusion_review.created_at >= CONCLUSION_REVIEW_SORT_BY_RISK_START
  end

  def bic_current_weaknesses conclusion_review
    weaknesses = base_weaknesses conclusion_review
    present    = weaknesses.not_revoked.where repeated_of_id: nil

    present.reorder risk: :desc, priority: :desc, review_code: :asc
  end

  def bic_repeated_weaknesses conclusion_review
    weaknesses = base_weaknesses conclusion_review
    repeated   = weaknesses.not_revoked.where.not repeated_of_id: nil

    repeated.reorder risk: :desc, priority: :desc, review_code: :asc
  end

  def bic_control_objective_item_weaknesses conclusion_review, control_objective_item
    weaknesses = if kind_of? ConclusionFinalReview
                   control_objective_item.final_weaknesses
                 else
                   control_objective_item.weaknesses
                 end

    weaknesses = conclusion_review.bic_exclude_regularized_findings weaknesses

    weaknesses.not_revoked.sort_for_review
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

  def format_and_sanitize input_text
    formatted_text     = input_text.gsub(/\n/, '<br>')
    allowed_tags       = %w[b i em strong u br small sub sup mark p div span ul ol li]
    sanitized_text     = sanitize formatted_text, tags: allowed_tags

    raw sanitized_text
  end

  private

    def base_weaknesses conclusion_review
      weaknesses = if conclusion_review.draft?
                     conclusion_review.review.weaknesses
                   else
                     conclusion_review.review.final_weaknesses
                   end

      conclusion_review.bic_exclude_regularized_findings weaknesses
    end
end
