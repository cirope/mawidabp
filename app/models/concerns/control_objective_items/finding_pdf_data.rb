module ControlObjectiveItems::FindingPdfData
  extend ActiveSupport::Concern

  def finding_pdf_data finding, hide: [], show: [], change_name: []
    body = ''

    body << get_initial_finding_attributes(finding, hide, show, change_name)
    body << get_weakness_attributes(finding, hide, change_name) if finding.kind_of?(Weakness)
    body << get_finding_answer(finding, change_name)
    body << get_audited_data(finding, hide, change_name)
    body << get_late_finding_attributes(finding, show, change_name)
    body << get_final_finding_attributes(finding, hide, show)

    body
  end

  private

    def get_initial_finding_attributes finding, hide, show, change_name
      body = ''

      if finding.title.present? && hide.exclude?('title')
        body << "<b>#{finding.class.human_attribute_name('title')}: " +
          "<i>#{finding.title.chomp}</i></b>\n"
      end

      if finding.review_code.present? && hide.exclude?('review_code')
        body << finding_review_code_text_for(finding, show)
      end

      if finding.description.present? && hide.exclude?('description')
        body << "<b>#{finding.class.human_attribute_name('description')}:</b> " +
          "#{finding.description.chomp}\n"
      end

      if show.include? 'review'
        body << "<b>#{Review.model_name.human}:</b> " +
          "<i>#{finding.review.identification}</i></b>\n"
      end

      if finding.origination_date.present? && hide.exclude?('origination_date')
        if change_name.include? 'origination_date'
          body << "<b>#{I18n.t 'conclusion_review.cro.findings.origination_date'}:"+
            "</b> #{finding_origination_date_text_for finding}\n"
        else
          body << "<b>#{finding.class.human_attribute_name('origination_date')}:"+
            "</b> #{finding_origination_date_text_for finding}\n"
        end
      end

      body << finding_repeated_text_for(finding, show)
    end

    def get_weakness_attributes finding, hide, change_name
      body = ''

      if finding.risk_text.present?
        if change_name.include? 'risk'
          body << "<b>#{I18n.t 'conclusion_review.cro.weakness.risk'}:</b> " +
            "#{finding.risk_text.chomp}\n"
        else
          body << "<b>#{Weakness.human_attribute_name('risk')}:</b> " +
            "#{finding.risk_text.chomp}\n"
        end
      end

      if !HIDE_WEAKNESS_EFFECT && finding.effect.present?
        if change_name.include? 'risk'
          body << "<b>#{I18n.t 'conclusion_review.cro.weakness.effect'}:</b> " +
            "#{finding.effect.chomp}\n"
        else
          body << "<b>#{Weakness.human_attribute_name('effect')}:</b> " +
            "#{finding.effect.chomp}\n"
        end
      end

      if finding.audit_recommendations.present? && hide.exclude?('audit_recommendations')
        if change_name.include? 'audit_recommendations'
          body << "<b>#{I18n.t 'conclusion_review.cro.weakness.audit_recommendations'}: " +
            "</b>#{finding.audit_recommendations}\n"
        else
          body << "<b>#{Weakness.human_attribute_name('audit_recommendations')}: " +
            "</b>#{finding.audit_recommendations}\n"
        end
      end

      body
    end

    def get_finding_answer finding, change_name
      body = ''

      if finding.answer.present?
        if change_name.include? 'answer'
          body << "<b>#{I18n.t 'conclusion_review.cro.findings.answer'}:</b> " +
          "#{finding.answer.chomp}\n"
        else
          body << "<b>#{finding.class.human_attribute_name('answer')}:</b> " +
          "#{finding.answer.chomp}\n"
        end
      end

      body
    end


    def get_late_finding_attributes finding, show, change_name
      body = ''

      body << get_tasks_data(finding)
      body << finding_follow_up_date_text_for(finding, show, change_name)

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

    def get_audited_data finding, hide, change_name
      body          = ''
      process_owner = FindingUserAssignment.human_attribute_name 'process_owner'
      audited_users = finding.users.select &:can_act_as_audited?

      if audited_users.present? && hide.exclude?('audited')
        process_owners = finding.process_owners
        users          = audited_users.map do |u|
          u.full_name + (process_owners.include?(u) ? " (#{process_owner})" : '')
        end
        if change_name.include? 'user_ids'
          body << "<b>#{I18n.t 'conclusion_review.cro.findings.user_ids'}:</b> " +
            "#{users.join('; ')}\n"
        else
          body << "<b>#{finding.class.human_attribute_name('user_ids')}:</b> " +
            "#{users.join('; ')}\n"
        end
      end

      body
    end

    def get_final_finding_attributes finding, hide, show
      body = ''

      if show.include? 'current_situation'
        body << "<b>#{finding.class.human_attribute_name('current_situation')}:</b> " +
          "#{finding.current_situation}\n"
      end

      if finding.state_text.present? && hide.exclude?('state')
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
      if Current.conclusion_pdf_format != 'gal' || finding.repeated_ancestors.present?
        I18n.l finding.origination_date, format: :long
      else
        I18n.t 'conclusion_review.new_origination_date'
      end
    end

    def finding_follow_up_date_text_for finding, show, change_name
      display =
        (Current.conclusion_pdf_format != 'gal' && finding.follow_up_date.present?) ||
        (finding.follow_up_date.present? && !finding.implemented_audited?)

      if display && show.include?('estimated_follow_up')
        "<b>#{I18n.t 'conclusion_review.estimated_follow_up_date'}:</b> " +
          "#{I18n.l(finding.follow_up_date, format: '%B %Y')}\n"
      elsif display
        if change_name.include?('follow_up_date')
          "<b>#{I18n.t 'conclusion_review.cro.findings.estimated_follow_up_date'}:</b> " +
          "#{I18n.l(finding.follow_up_date, format: :long)}\n"
        else
          "<b>#{finding.class.human_attribute_name('follow_up_date')}:</b> " +
            "#{I18n.l(finding.follow_up_date, format: :long)}\n"
        end
      else
        ''
      end
    end

    def finding_repeated_text_for finding, show
      repeated = finding.repeated_ancestors.present?

      if Current.conclusion_pdf_format == 'gal'
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
