module ConclusionFinalReviewsHelper
  def conclusion_final_review_review_field(form, review)
    reviews = (Review.list_with_approved_draft - Review.list_with_final_review) |
      [review]
    options = reviews.compact.map { |r| [r.identification, r.id] }

    form.input :review_id, collection: options, prompt: true,
      input_html: { autofocus: true }
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

    if weakness && finding.effect.present?
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

    if weakness && finding.correction.present?
      body_rows << "<strong>#{finding.class.human_attribute_name(
      :correction)}: </strong>#{finding.correction}"
    end

    if weakness && finding.correction_date.present?
      body_rows << "<strong>#{finding.class.human_attribute_name(
      :correction_date)}: </strong> #{I18n.l(finding.correction_date,
        :format => :long)}"
    end

    if weakness && finding.cause_analysis.present?
      body_rows << "<strong>#{finding.class.human_attribute_name(
      :cause_analysis)}: </strong>#{finding.cause_analysis}"
    end

    if weakness && finding.cause_analysis_date.present?
      body_rows << "<strong>#{finding.class.human_attribute_name(
      :cause_analysis_date)}: </strong> #{I18n.l(finding.cause_analysis_date,
        :format => :long)}"
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

  def send_review_options
    options = ['normal', 'brief', 'without_score'].map do |type|
      [t("conclusion_final_review.send_type.#{type}"), type]
    end

    options_for_select options, 'normal'
  end
end
