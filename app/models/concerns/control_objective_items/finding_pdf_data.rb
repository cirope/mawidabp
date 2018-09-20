module ControlObjectiveItems::FindingPDFData
  extend ActiveSupport::Concern

  def finding_pdf_data finding, hide: [], show: []
    body = ''

    body << get_initial_finding_attributes(finding, show)
    body << get_weakness_attributes(finding, hide) if finding.kind_of?(Weakness)
    body << get_late_finding_attributes(finding, show)
    body << get_audited_data(finding, hide)
    body << get_final_finding_attributes(finding, hide, show)

    body
  end

  private

    def get_initial_finding_attributes finding, show
      body = ''

      if finding.review_code.present?
        body << finding_review_code_text_for(finding, show)
      end

      if finding.title.present?
        body << "<b>#{finding.class.human_attribute_name('title')}: " +
          "<i>#{finding.title.chomp}</i></b>\n"
      end

      if finding.description.present?
        body << "<b>#{finding.class.human_attribute_name('description')}:</b> " +
          "#{finding.description.chomp}\n"
      end

      body << finding_repeated_text_for(finding, show)
    end

    def get_weakness_attributes finding, hide
      body = ''

      if finding.risk_text.present?
        body << "<b>#{Weakness.human_attribute_name('risk')}:</b> " +
          "#{finding.risk_text.chomp}\n"
      end

      if !HIDE_WEAKNESS_EFFECT && finding.effect.present?
        body << "<b>#{Weakness.human_attribute_name('effect')}:</b> " +
          "#{finding.effect.chomp}\n"
      end

      if finding.audit_recommendations.present? && hide.exclude?('audit_recommendations')
        body << "<b>#{Weakness.human_attribute_name('audit_recommendations')}: " +
          "</b>#{finding.audit_recommendations}\n"
      end

      body
    end

    def get_late_finding_attributes finding, show
      body = ''

      if finding.origination_date.present?
        body << "<b>#{finding.class.human_attribute_name('origination_date')}:"+
          "</b> #{finding_origination_date_text_for finding}\n"
      end

      if finding.answer.present?
        body << "<b>#{finding.class.human_attribute_name('answer')}:</b> " +
          "#{finding.answer.chomp}\n"
      end

      body << get_tasks_data(finding)
      body << finding_follow_up_date_text_for(finding, show)

      if finding.solution_date.present?
        body << "<b>#{finding.class.human_attribute_name('solution_date')}:" +
          "</b> #{I18n.l(finding.solution_date, format: :long)}\n"
      end

      body
    end

    def get_tasks_data finding
      body = ''

      if finding.tasks.any?
        body << "<b>#{Task.model_name.human count: 0}</b>\n"

        finding.tasks.each do |task|
          body << "#{Prawn::Text::NBSP * 2}• #{task.detailed_description}\n"
        end
      end

      body
    end

    def get_audited_data finding, hide
      body          = ''
      process_owner = FindingUserAssignment.human_attribute_name 'process_owner'
      audited_users = finding.users.select &:can_act_as_audited?

      if audited_users.present? && hide.exclude?('audited')
        process_owners = finding.process_owners
        users          = audited_users.map do |u|
          u.full_name + (process_owners.include?(u) ? " (#{process_owner})" : '')
        end

        body << "<b>#{finding.class.human_attribute_name('user_ids')}:</b> " +
          "#{users.join('; ')}\n"
      end

      body
    end

    def get_final_finding_attributes finding, hide, show
      body = ''

      if finding.state_text.present?
        body << "<b>#{finding.class.human_attribute_name('state')}:</b> " +
          "#{finding.state_text.chomp}\n"
      end

      if finding.audit_comments.present? && hide.exclude?('audit_comments')
        body << "<b>#{finding.class.human_attribute_name('audit_comments')}:" +
          "</b> #{finding.audit_comments.chomp}\n"
      end

      if finding.business_units.present?
        body << "<b>#{BusinessUnit.model_name.human count: finding.business_units.size}:" +
          "</b> #{finding.business_units.map(&:name).join(', ')}\n"
      end

      body
    end

    def finding_review_code_text_for finding, show
      show_template_code = show.include?('template_code') &&
                           finding.weakness_template_id.blank?
      code               = if show_template_code
                             "#{finding.review_code} <sub><b>(NE)</b></sub>"
                           else
                             finding.review_code
                           end

      "<b>#{finding.class.human_attribute_name 'review_code'}:</b> #{code}\n"
    end

    def finding_origination_date_text_for finding
      if !SHOW_CONCLUSION_ALTERNATIVE_PDF || finding.repeated_ancestors.present?
        I18n.l finding.origination_date, format: :long
      else
        I18n.t 'conclusion_review.new_origination_date'
      end
    end

    def finding_follow_up_date_text_for finding, show
      display =
        (!SHOW_CONCLUSION_ALTERNATIVE_PDF && finding.follow_up_date.present?) ||
        (finding.follow_up_date.present? && !finding.implemented_audited?)

      if display && show.include?('estimated_follow_up')
        "<b>#{I18n.t 'conclusion_review.estimated_follow_up_date'}:</b> " +
          "#{I18n.l(finding.follow_up_date, format: '%B %Y')}\n"
      elsif display
        "<b>#{finding.class.human_attribute_name('follow_up_date')}:</b> " +
          "#{I18n.l(finding.follow_up_date, format: :long)}\n"
      else
        ''
      end
    end

    def finding_repeated_text_for finding, show
      repeated = finding.repeated_ancestors.present?

      if SHOW_CONCLUSION_ALTERNATIVE_PDF
        label = I18n.t "label.#{repeated ? 'yes' : 'no'}"

        if show.include?('repeated_review') && finding.repeated_of
          review_identification = [
            I18n.t('conclusion_review.review_repeated_finding_label'),
            finding.repeated_of.review.identification
          ].join(' ')

          label << " (#{review_identification})"
        end

        "<b>#{I18n.t 'findings.state.repeated'}:</b> #{label}\n"
      elsif repeated
        "<b>#{finding.class.human_attribute_name('repeated_of_id')}:</b>" +
          " #{finding.repeated_ancestors.join(' | ')}\n"
      else
        ''
      end
    end
end
