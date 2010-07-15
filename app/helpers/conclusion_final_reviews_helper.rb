module ConclusionFinalReviewsHelper
  def conclusion_final_review_review_field(form, review)
    reviews = (Review.list_with_approved_draft - Review.list_with_final_review) |
      [review]
    options = reviews.compact.map { |r| [r.identification, r.id] }

    form.select :review_id, options, {:prompt => true},
      {:class => 'inline_item focused'}
  end

  def conclusion_review_score_details_table(review)
    scores = review.get_parameter(:admin_review_scores)
    review_score = review.score.first
    header = String.new
    footer = String.new
    width = (100.0 / scores.size).truncate

    scores.sort! { |s1, s2| s2[1].to_i <=> s1[1].to_i }

    scores.each_with_index do |score, i|
      min_percentage = score[1]
      max_percentage = i > 0 && scores[i - 1] ? scores[i - 1][1] - 1 : 100
      column_text = "#{score[0]}"

      header << content_tag(:th, (score[0] != review_score ?
            "<span style=\"font-weight: normal;\">#{column_text}</span>" :
            "<b>#{column_text.upcase} (#{review.effectiveness}%)</b>"),
        :style => "width: #{width}%;")

      footer << content_tag(:td, "#{max_percentage}% - #{min_percentage}%")
    end

    content_tag(:table, content_tag(:thead, content_tag(:tr, header)) +
        content_tag(:tbody, content_tag(:tr, footer)), :class => :summary_table)
  end

  def conclusion_review_process_control_weakness_details_table(process_control,
      cois, use_finals = false)
    has_observations = cois.any? do |coi|
      !(use_finals ? coi.final_weaknesses : coi.weaknesses).blank?
    end

    if has_observations
      header = String.new
      body = String.new

      header = content_tag :tr, content_tag(:td,
        "#{ProcessControl.human_name}: #{h(process_control.name)}",
        :class => :header)

      cois.each do |coi|
        (use_finals ? coi.final_weaknesses : coi.weaknesses).each do |w|
          body << weakness_row_data(coi, w, cycle(:odd, :even, :name => :wc))
        end
      end

      reset_cycle :wc

      header + body
    end
  end

  def conclusion_review_process_control_oportunity_details_table(
      process_control, cois, use_finals = false)
    has_oportunities = cois.any? do |coi|
      !(use_finals ? coi.final_oportunities : coi.oportunities).blank?
    end

    if has_oportunities
      header = String.new
      body = String.new

      header = content_tag :tr, content_tag(:td,
        "#{ProcessControl.human_name}: #{h(process_control.name)}",
        :class => :header)

      cois.each do |coi|
        (use_finals ? coi.final_oportunities : coi.oportunities).each do |o|
          body << weakness_row_data(coi, o, cycle(:odd, :even))
        end
      end

      header + body
    end
  end

  def weakness_row_data(coi, finding, html_class = nil)
    weakness = finding.kind_of?(Weakness)
    body_rows = ["<b>#{ControlObjective.human_name}:</b> " +
      "#{h(coi.control_objective_text)}"]

    unless finding.review_code.blank?
      body_rows << "<b>#{finding.class.human_attribute_name(
      'review_code')}:</b> #{h(finding.review_code)}"
    end

    unless finding.description.blank?
      body_rows << "<b>#{finding.class.human_attribute_name(
      'description')}:</b> #{h(finding.description)}"
    end

    if weakness && !finding.risk_text.blank?
      body_rows << "<b>#{Weakness.human_attribute_name('risk')}:</b> " +
        "#{h(finding.risk_text)}"
    end

    if weakness && !finding.effect.blank?
      body_rows << "<b>#{Weakness.human_attribute_name('effect')}:</b> " +
        "#{h(finding.effect)}"
    end

    if weakness && !finding.audit_recommendations.blank?
      body_rows << "<b>#{Weakness.human_attribute_name(
      'audit_recommendations')}: </b>#{h(finding.audit_recommendations)}"
    end

    unless finding.answer.blank?
      body_rows << "<b>#{finding.class.human_attribute_name('answer')}:</b> " +
        "#{h(finding.answer)}"
    end

    if weakness && !finding.implemented_audited?
      unless finding.follow_up_date.blank?
        body_rows << "<b>#{Weakness.human_attribute_name(
        'follow_up_date')}:</b> #{I18n.l(finding.follow_up_date,
        :format => :long)}"
      end
    elsif !finding.solution_date.blank?
      body_rows << "<b>#{finding.class.human_attribute_name('solution_date')}:"+
        "</b> #{I18n.l(finding.solution_date, :format => :long)}"
    end

    audited_users = finding.users.select { |u| u.audited? }

    unless audited_users.blank?
      body_rows << "<b>#{finding.class.human_attribute_name(
      'user_ids')}:</b> #{h(audited_users.map { |u| u.full_name }.join('; '))}"
    end

    unless finding.audit_comments.blank?
      body_rows << "<b>#{finding.class.human_attribute_name(
      'audit_comments')}: </b> #{h(finding.audit_comments)}"
    end

    unless finding.state_text.blank?
      body_rows << "<b>#{finding.class.human_attribute_name('state')}:</b> " +
        h(finding.state_text)
    end

    content_tag(:tr, content_tag(:td,
        body_rows.map {|r| content_tag(:p, r)}.join), :class => html_class)
  end
end