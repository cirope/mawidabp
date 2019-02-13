module ConclusionFinalReviewsHelper
  def conclusion_final_review_review_field(form, review)
    reviews = (Review.list_with_approved_draft - Review.list_with_final_review) |
      [review]
    options = reviews.compact.map do |r|
      [truncate(r.long_identification, length: 50), r.id]
    end

    form.input :review_id, collection: options, prompt: true,
      input_html: { autofocus: true }
  end

  def conclusion_review_score_text(review)
    review_score = review.score_array.first

    content_tag(:strong) do
      "#{t 'review.score'}: #{t("score_types.#{review_score}").upcase}"
    end
  end

  def conclusion_review_score_details_table(review)
    scores = review.class.scores.to_a
    review_score = review.score_array.first
    header = String.new.html_safe
    footer = String.new.html_safe
    width = (100.0 / scores.size).truncate

    scores.sort! { |s1, s2| s2[1].to_i <=> s1[1].to_i }

    scores.each_with_index do |score, i|
      min_percentage = score[1]
      max_percentage = i > 0 && scores[i - 1] ? scores[i - 1][1] - 1 : 100
      column_text = t("score_types.#{score[0]}")

      header << content_tag(:th, (score[0] != review_score ?
            raw("<span style=\"font-weight: normal;\">#{column_text}</span>"):
            raw("<strong>#{column_text.upcase} (#{review.score}%)</strong>")),
        :style => "width: #{width}%;")

      footer << content_tag(:td, "#{max_percentage}% - #{min_percentage}%")
    end

    content_tag(:table, content_tag(:thead, content_tag(:tr, header)) +
        content_tag(:tbody, content_tag(:tr, footer)), class: 'table table-condensed table-striped')
  end

  def conclusion_review_process_control_weakness_details_table(process_control, cois, use_finals = false)
    has_observations = cois.any? do |coi|
      (use_finals ? coi.final_weaknesses : coi.weaknesses).not_revoked.present?
    end

    if has_observations
      header = String.new.html_safe
      body = String.new.html_safe

      header = content_tag :tr, content_tag(:td, "#{ProcessControl.model_name.human}: #{process_control.name}")

      cois.each do |coi|
        (use_finals ? coi.final_weaknesses : coi.weaknesses).not_revoked.sort_for_review.each do |w|
          body << finding_row_data(coi, w)
        end
      end

      header + body
    end
  end

  def conclusion_review_process_control_oportunity_details_table(
      process_control, cois, use_finals = false)
    has_oportunities = cois.any? do |coi|
      !(use_finals ? coi.final_oportunities : coi.oportunities).not_revoked.blank?
    end

    if has_oportunities
      header = String.new.html_safe
      body = String.new.html_safe

      header = content_tag :tr, content_tag(:td,
        "#{ProcessControl.model_name.human}: #{process_control.name}")

      cois.each do |coi|
        (use_finals ? coi.final_oportunities : coi.oportunities).not_revoked.each do |o|
          body << finding_row_data(coi, o)
        end
      end

      header + body
    end
  end

  def finding_row_data(coi, finding, html_class = nil)
    weakness = finding.kind_of?(Weakness)
    oportunity = finding.kind_of?(Oportunity)

    body_rows = ["<strong>#{ControlObjective.model_name.human}:</strong> #{coi.to_s}"]

    if finding.description.present?
      body_rows << "<strong>#{finding.class.human_attribute_name(
      :description)}:</strong> #{finding.description}"
    end

    if finding.review_code.present?
      body_rows << "<strong>#{finding.class.human_attribute_name(
      :review_code)}:</strong> #{finding.review_code}"
    end

    if finding.title.present?
      body_rows << "<strong>#{finding.class.human_attribute_name(
      :title)}:</strong> #{finding.title}"
    end

    if finding.repeated_ancestors.present? && (weakness || oportunity)
      body_rows << "<strong>#{finding.class.human_attribute_name(
      :repeated_of_id)}:</strong> #{finding.repeated_ancestors.join(' | ')}"
    end

    if weakness && finding.risk_text.present?
      body_rows << "<strong>#{finding.class.human_attribute_name(:risk)}:</strong> " +
        "#{finding.risk_text}"
    end

    if !HIDE_WEAKNESS_EFFECT && weakness && finding.effect.present?
      body_rows << "<strong>#{finding.class.human_attribute_name(:effect)}:</strong> " +
        "#{finding.effect}"
    end

    if weakness && finding.audit_recommendations.present?
      body_rows << "<strong>#{finding.class.human_attribute_name(
      :audit_recommendations)}: </strong>#{finding.audit_recommendations}"
    end

    if finding.origination_date.present?
      body_rows << "<strong>#{finding.class.human_attribute_name(:origination_date)}:</strong> " +
        "#{I18n.l(finding.origination_date, :format => :long)}"
    end

    if finding.answer.present?
      body_rows << "<strong>#{finding.class.human_attribute_name(:answer)}:</strong> " +
        "#{h(finding.answer)}"
    end

    if finding.follow_up_date.present?
      body_rows << "<strong>#{finding.class.human_attribute_name(
        :follow_up_date)}:</strong> #{I18n.l(finding.follow_up_date,
        :format => :long)}"
    end

    if finding.solution_date.present?
      body_rows << "<strong>#{finding.class.human_attribute_name(:solution_date)}:"+
        "</strong> #{I18n.l(finding.solution_date, :format => :long)}"
    end

    audited_users = finding.users.select(&:can_act_as_audited?)

    if audited_users.present?
      process_owners = finding.process_owners
      users = audited_users.map do |u|
        u.full_name + (process_owners.include?(u) ?
            " (#{FindingUserAssignment.human_attribute_name(:process_owner)})" : '')
      end

      body_rows << "<strong>#{finding.class.human_attribute_name(:user_ids)}:</strong> #{users.join('; ')}"
    end

    if finding.state_text.present? && (weakness || oportunity)
      body_rows << "<strong>#{finding.class.human_attribute_name(:state)}:</strong> " +
        h(finding.state_text)
    end

    if finding.audit_comments.present?
      body_rows << "<strong>#{finding.class.human_attribute_name(:audit_comments)}: </strong> #{finding.audit_comments}"
    end

    if finding.business_units.present?
      body_rows << "<strong>#{BusinessUnit.model_name.human count: finding.business_units.size}:</strong> " +
        "<ul>#{finding.business_units.map { |bu| "<li>#{bu.name}</li>" }.join}</ul>"
    end

    content_tag(:tr, content_tag(:td, raw(body_rows.map { |r| content_tag(:div, raw(r)) }.join)))
  end

  def users_for_conclusion_review_questionnaire
    @conclusion_final_review.review.users.reject do |user|
      user.can_act_as_audited? || user.new_record?
    end
  end

  def send_review_options
    default = if Current.conclusion_pdf_format == 'gal' && show_brief_download?
                'brief'
              else
                'normal'
              end

    options = if Current.conclusion_pdf_format == 'default'
                ['normal', 'brief', 'without_score']
              else
                ['normal', 'brief']
              end

    options.delete 'brief' unless show_brief_download?

    select_options = options.map do |type|
      [t("conclusion_final_review.send_type.#{type}"), type]
    end

    options_for_select select_options, default
  end

  def show_review_best_practice_comments?
    prefix = current_organization&.prefix

    SHOW_REVIEW_BEST_PRACTICE_COMMENTS &&
      ORGANIZATIONS_WITH_BEST_PRACTICE_COMMENTS.include?(prefix)
  end

  def show_brief_download?
    !show_review_best_practice_comments? &&
      ORGANIZATIONS_WITH_CONTROL_OBJECTIVE_COUNTS.exclude?(current_organization.prefix)
  end

  def show_conclusion_review_issue_date conclusion_final_review
    issue_date = l(conclusion_final_review.issue_date, :format => :short) if conclusion_final_review.issue_date
    close_date = l(conclusion_final_review.close_date, :format => :short) if conclusion_final_review.close_date
    title      = "#{ConclusionDraftReview.human_attribute_name(:close_date)}: #{close_date}" if close_date

    content_tag :abbr, issue_date, title: title if issue_date
  end

  def conclusion_options
    CONCLUSION_OPTIONS.map { |option| [option, option] }
  end

  def can_destroy_final_reviews?
    ALLOW_CONCLUSION_FINAL_REVIEW_DESTRUCTION && can_perform?(:destroy)
  end
end
