module ControlObjectiveItems::FindingPDFData
  extend ActiveSupport::Concern

  def finding_pdf_data finding
    body = ''

    body << get_initial_finding_attributes(finding)
    body << get_weakness_attributes(finding) if finding.kind_of?(Weakness)
    body << get_late_finding_attributes(finding)
    body << get_optional_finding_attributes(finding)
    body << get_audited_data(finding)
    body << get_final_finding_attributes(finding)

    body
  end

  private

    def get_initial_finding_attributes finding
      body = ''

      if finding.review_code.present?
        body << "<b>#{finding.class.human_attribute_name('review_code')}:</b> " +
          "#{finding.review_code.chomp}\n"
      end

      if finding.title.present?
        body << "<b>#{finding.class.human_attribute_name('title')}:</b> " +
          "#{finding.title.chomp}\n"
      end

      if finding.description.present?
        body << "<b>#{finding.class.human_attribute_name('description')}:</b> " +
          "#{finding.description.chomp}\n"
      end

      if finding.repeated_ancestors.present?
        body << "<b>#{finding.class.human_attribute_name('repeated_of_id')}:</b>" +
          " #{finding.repeated_ancestors.join(' | ')}\n"
      end

      body
    end

    def get_weakness_attributes finding
      body = ''

      if finding.risk_text.present?
        body << "<b>#{Weakness.human_attribute_name('risk')}:</b> " +
          "#{finding.risk_text.chomp}\n"
      end

      if !HIDE_WEAKNESS_EFFECT && finding.effect.present?
        body << "<b>#{Weakness.human_attribute_name('effect')}:</b> " +
          "#{finding.effect.chomp}\n"
      end

      if finding.audit_recommendations.present?
        body << "<b>#{Weakness.human_attribute_name('audit_recommendations')}: " +
          "</b>#{finding.audit_recommendations}\n"
      end

      body
    end

    def get_late_finding_attributes finding
      body = ''

      if finding.origination_date.present?
        body << "<b>#{finding.class.human_attribute_name('origination_date')}:"+
          "</b> #{I18n.l(finding.origination_date, format: :long)}\n"
      end

      if finding.answer.present?
        body << "<b>#{finding.class.human_attribute_name('answer')}:</b> " +
          "#{finding.answer.chomp}\n"
      end

      if finding.follow_up_date.present?
        body << "<b>#{finding.class.human_attribute_name('follow_up_date')}:</b> " +
          "#{I18n.l(finding.follow_up_date, format: :long)}\n"
      end

      if finding.solution_date.present?
        body << "<b>#{finding.class.human_attribute_name('solution_date')}:" +
          "</b> #{I18n.l(finding.solution_date, format: :long)}\n"
      end

      body
    end

    def get_optional_finding_attributes finding
      body = ''

      if SHOW_WEAKNESS_EXTRA_ATTRIBUTES && finding.kind_of?(Weakness) &&
          finding.internal_control_components.any?
        body << "<b>#{finding.class.human_attribute_name('internal_control_components')}:" +
          "</b> #{finding.internal_control_components.to_sentence}\n"
      end

      body
    end

    def get_audited_data finding
      body          = ''
      process_owner = FindingUserAssignment.human_attribute_name 'process_owner'
      audited_users = finding.users.select &:can_act_as_audited?

      if audited_users.present?
        process_owners = finding.process_owners
        users          = audited_users.map do |u|
          u.full_name + (process_owners.include?(u) ? " (#{process_owner})" : '')
        end

        body << "<b>#{finding.class.human_attribute_name('user_ids')}:</b> " +
          "#{users.join('; ')}\n"
      end

      body
    end

    def get_final_finding_attributes finding
      body = ''

      if finding.state_text.present?
        body << "<b>#{finding.class.human_attribute_name('state')}:</b> " +
          "#{finding.state_text.chomp}\n"
      end

      if finding.audit_comments.present?
        body << "<b>#{finding.class.human_attribute_name('audit_comments')}:" +
          "</b> #{finding.audit_comments.chomp}\n"
      end

      if finding.business_units.present?
        body << "<b>#{BusinessUnit.model_name.human count: finding.business_units.size}:" +
          "</b> #{finding.business_units.map(&:name).join(', ')}\n"
      end

      body
    end
end
