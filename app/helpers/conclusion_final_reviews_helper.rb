module ConclusionFinalReviewsHelper
  def conclusion_final_review_review_field(form, review)
    reviews = (Review.list_with_approved_draft - Review.list_with_final_review) |
      [review]
    options = reviews.compact.map { |r| [r.identification, r.id] }

    form.select :review_id, options, {:prompt => true},
      {:class => :inline_item, :autofocus => true}
  end

  def conclusion_review_score_details_table(review)
    scores = review.class.scores(review.created_at).to_a
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
            raw("<b>#{column_text.upcase} (#{review.score}%)</b>")),
        :style => "width: #{width}%;")

      footer << content_tag(:td, "#{max_percentage}% - #{min_percentage}%")
    end

    content_tag(:table, content_tag(:thead, content_tag(:tr, header)) +
        content_tag(:tbody, content_tag(:tr, footer)), :class => :summary_table)
  end

  def conclusion_review_process_control_weakness_details_table(process_control,
      cois, use_finals = false)
    has_observations = cois.any? do |coi|
      !(use_finals ? coi.final_weaknesses : coi.weaknesses).not_revoked.blank?
    end

    if has_observations
      header = String.new.html_safe
      body = String.new.html_safe

      header = content_tag :tr, content_tag(:td,
        "#{ProcessControl.model_name.human}: #{h(process_control.name)}",
        :class => :header)

      cois.each do |coi|
        (use_finals ? coi.final_weaknesses : coi.weaknesses).not_revoked.each do |w|
          body << finding_row_data(coi, w, cycle(:odd, :even, :name => :wc))
        end
      end

      reset_cycle :wc

      header + body
    end
  end

  def conclusion_review_process_control_nonconformity_details_table(process_control,
      cois, use_finals = false)
    has_nonconformities = cois.any? do |coi|
      !(use_finals ? coi.final_nonconformities : coi.nonconformities).not_revoked.blank?
    end

    if has_nonconformities
      header = String.new.html_safe
      body = String.new.html_safe

      header = content_tag :tr, content_tag(:td,
        "#{ProcessControl.model_name.human}: #{process_control.name}",
        :class => :header)

      cois.each do |coi|
        (use_finals ? coi.final_nonconformities : coi.nonconformities).not_revoked.each do |nc|
          body << finding_row_data(coi, nc, cycle(:odd, :even, :name => :wc))
        end
      end

      reset_cycle :wc

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
        "#{ProcessControl.model_name.human}: #{h(process_control.name)}",
        :class => :header)

      cois.each do |coi|
        (use_finals ? coi.final_oportunities : coi.oportunities).not_revoked.each do |o|
          body << finding_row_data(coi, o, cycle(:odd, :even))
        end
      end

      header + body
    end
  end

  def conclusion_review_process_control_potential_nonconformity_details_table(
      process_control, cois, use_finals = false)
    has_potential_nonconformities = cois.any? do |coi|
      !(use_finals ? coi.final_potential_nonconformities : coi.potential_nonconformities).not_revoked.blank?
    end

    if has_potential_nonconformities
      header = String.new.html_safe
      body = String.new.html_safe

      header = content_tag :tr, content_tag(:td,
        "#{ProcessControl.model_name.human}: #{h(process_control.name)}",
        :class => :header)

      cois.each do |coi|
        (use_finals ? coi.final_potential_nonconformities : coi.potential_nonconformities).not_revoked.each do |p_nc|
          body << finding_row_data(coi, p_nc, cycle(:odd, :even))
        end
      end

      header + body
    end
  end

  def conclusion_review_process_control_fortress_details_table(
      process_control, cois, use_finals = false)
    has_fortresses = cois.any? do |coi|
      !(use_finals ? coi.final_fortresses : coi.fortresses).blank?
    end

    if has_fortresses
      header = String.new.html_safe
      body = String.new.html_safe

      header = content_tag :tr, content_tag(:td,
        "#{ProcessControl.model_name.human}: #{h(process_control.name)}",
        :class => :header)

      cois.each do |coi|
        (use_finals ? coi.final_fortresses : coi.fortresses).each do |f|
          body << finding_row_data(coi, f, cycle(:odd, :even))
        end
      end

      header + body
    end
  end

  def finding_row_data(coi, finding, html_class = nil)
    weakness = finding.kind_of?(Weakness) || finding.kind_of?(Nonconformity)
    oportunity = finding.kind_of?(Oportunity) || finding.kind_of?(PotentialNonconformity)

    body_rows = ["<b>#{ControlObjective.model_name.human}:</b> #{h(coi.to_s)}"]

    if finding.description.present?
      body_rows << "<b>#{finding.class.human_attribute_name(
      :description)}:</b> #{h(finding.description)}"
    end

    if finding.review_code.present?
      body_rows << "<b>#{finding.class.human_attribute_name(
      :review_code)}:</b> #{h(finding.review_code)}"
    end

    if finding.repeated_ancestors.present? && (weakness || oportunity)
      body_rows << "<b>#{finding.class.human_attribute_name(
      :repeated_of_id)}:</b> #{h(finding.repeated_ancestors.join(' | '))}"
    end

    if weakness && finding.risk_text.present?
      body_rows << "<b>#{finding.class.human_attribute_name(:risk)}:</b> " +
        "#{h(finding.risk_text)}"
    end

    if weakness && finding.effect.present?
      body_rows << "<b>#{finding.class.human_attribute_name(:effect)}:</b> " +
        "#{h(finding.effect)}"
    end

    if weakness && finding.audit_recommendations.present?
      body_rows << "<b>#{finding.class.human_attribute_name(
      :audit_recommendations)}: </b>#{h(finding.audit_recommendations)}"
    end

    if finding.origination_date.present?
      body_rows << "<b>#{finding.class.human_attribute_name(:origination_date)}:</b> " +
        "#{I18n.l(finding.origination_date, :format => :long)}"
    end

    if weakness && finding.correction.present?
      body_rows << "<b>#{finding.class.human_attribute_name(
      :correction)}: </b>#{finding.correction}"
    end

    if weakness && finding.correction_date.present?
      body_rows << "<b>#{finding.class.human_attribute_name(
      :correction_date)}: </b> #{I18n.l(finding.correction_date,
        :format => :long)}"
    end

    if weakness && finding.cause_analysis.present?
      body_rows << "<b>#{finding.class.human_attribute_name(
      :cause_analysis)}: </b>#{finding.cause_analysis}"
    end

    if weakness && finding.cause_analysis_date.present?
      body_rows << "<b>#{finding.class.human_attribute_name(
      :cause_analysis_date)}: </b> #{I18n.l(finding.cause_analysis_date,
        :format => :long)}"
    end

    if finding.answer.present?
      body_rows << "<b>#{finding.class.human_attribute_name(:answer)}:</b> " +
        "#{h(finding.answer)}"
    end

    if finding.follow_up_date.present?
      body_rows << "<b>#{finding.class.human_attribute_name(
        :follow_up_date)}:</b> #{I18n.l(finding.follow_up_date,
        :format => :long)}"
    end

    if finding.solution_date.present?
      body_rows << "<b>#{finding.class.human_attribute_name(:solution_date)}:"+
        "</b> #{I18n.l(finding.solution_date, :format => :long)}"
    end

    audited_users = finding.users.select(&:can_act_as_audited?)

    if audited_users.present?
      process_owners = finding.process_owners
      users = audited_users.map do |u|
        u.full_name + (process_owners.include?(u) ?
            " (#{FindingUserAssignment.human_attribute_name(:process_owner)})" : '')
      end

      body_rows << "<b>#{finding.class.human_attribute_name(
      :user_ids)}:</b> #{h(users.join('; '))}"
    end

    if finding.state_text.present? && (weakness || oportunity)
      body_rows << "<b>#{finding.class.human_attribute_name(:state)}:</b> " +
        h(finding.state_text)
    end

    if finding.audit_comments.present?
      body_rows << "<b>#{finding.class.human_attribute_name(
      :audit_comments)}: </b> #{h(finding.audit_comments)}"
    end

    content_tag(:tr, content_tag(:td,
        raw(body_rows.map {|r| content_tag(:p, raw(r))}.join)),
      :class => html_class)
  end
end
