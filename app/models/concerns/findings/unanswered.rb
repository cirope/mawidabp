module Findings::Unanswered
  extend ActiveSupport::Concern

  module ClassMethods
    def mark_as_unanswered_if_necesary
      unless [0, 6].include?(Time.zone.today.wday)
        findings = []

        transaction do
          findings |= confirmed_and_stale_with_auditeds
          findings |= unconfirmed_and_stale_with_auditeds

          mark_as_unanswered_and_notify findings
        end
      end
    end

    def confirmed_and_stale_with_auditeds
      confirmed_and_stale.reject do |c_f|
        # Si o si hacer un reload, sino trae la asociación de la consulta
        c_f.finding_answers.reload.any? { |fa| fa.user.can_act_as_audited? }
      end
    end

    def confirmed_and_stale
      includes(:finding_answers, { control_objective_item: { review: :period } }).where(
        [
          "(#{confirmed_pre_conditions.map { |c| "(#{c})" }.join(' OR ')})",
          confirmed_fix_conditions
        ].join(' AND '),
        confirmed_parameters
      ).references(:periods)
    end

    def unconfirmed_and_stale_with_auditeds
      unconfirmed_and_stale.reject do |u_f|
        # Si o si hacer un reload, sino trae la asociación de la consulta
        u_f.finding_answers.reload.any? { |fa| fa.user.can_act_as_audited? }
      end
    end

    def unconfirmed_and_stale
      includes(control_objective_item: { review: :period }).where(
        [
          "(#{unconfirmed_pre_conditions.map { |c| "(#{c})" }.join(' OR ')})",
          unconfirmed_fix_conditions
        ].join(' AND '),
        unconfirmed_parameters
      ).references(:periods)
    end

    private

      def mark_as_unanswered_and_notify findings
        users = findings.inject([]) do |u, finding|
          finding.update_column :state, Finding::STATUS[:unanswered]
          u | finding.users
        end

        users.each do |user|
          findings_for_user = findings.select { |f| f.users.include? user }

          NotifierMailer.unanswered_findings_notification(user, findings_for_user).deliver_later
        end
      end

      def confirmed_pre_conditions
        stale_parameters.each_with_index.map do |stale_parameter, i|
          [
            "#{quoted_table_name}.#{qcn 'first_notification_date'} <= :stale_first_notification_date_#{i}",
            "#{quoted_table_name}.#{qcn 'organization_id'} = :organization_id_#{i}"
          ].join(' AND ')
        end
      end

      def confirmed_parameters
        parameters = {
          state: Finding::STATUS[:confirmed],
          boolean_false: false,
          notification_level: 0
        }

        stale_parameters.each_with_index do |stale_parameter, i|
          stale_days = stale_parameter[:parameter].to_i
          parameters[:"stale_first_notification_date_#{i}"] = stale_days.days.ago_in_business.to_date
          parameters[:"organization_id_#{i}"] = stale_parameter[:organization].id
        end

        parameters
      end

      def confirmed_fix_conditions
        [
          "#{quoted_table_name}.#{qcn 'state'} = :state",
          "#{quoted_table_name}.#{qcn 'final'} = :boolean_false",
          "#{quoted_table_name}.#{qcn 'notification_level'} = :notification_level"
        ].join(' AND ')
      end

      def unconfirmed_pre_conditions
        stale_parameters.each_with_index.map do |stale_parameter, i|
          [
            "#{quoted_table_name}.#{qcn 'first_notification_date'} <= :stale_first_notification_date_#{i}",
            "#{Period.quoted_table_name}.#{Period.qcn 'organization_id'} = :organization_id_#{i}",
          ].join(' AND ')
        end
      end

      def unconfirmed_parameters
        parameters = {
          state: Finding::STATUS[:unconfirmed],
          boolean_false: false
        }

        stale_parameters.each_with_index do |stale_parameter, i|
          stale_days = stale_parameter[:parameter].to_i
          parameters[:"stale_first_notification_date_#{i}"] = stale_days.days.ago_in_business.to_date
          parameters[:"organization_id_#{i}"] = stale_parameter[:organization].id
        end

        parameters
      end

      def unconfirmed_fix_conditions
        [
          "#{quoted_table_name}.#{qcn 'state'} = :state",
          "#{quoted_table_name}.#{qcn 'final'} = :boolean_false"
        ].join(' AND ')
      end

      def stale_parameters
        Organization.all_parameters 'finding_stale_confirmed_days'
      end
  end
end
