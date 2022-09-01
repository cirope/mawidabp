module Findings::ProcessEmail
  extend ActiveSupport::Concern

  module ClassMethods
    def receive_mail mail
      finding_id = extract_finding_id mail
      user       = find_user(mail, finding_id) if finding_id
      finding    = set_finding(finding_id, user) if user

      if finding
        finding.finding_answers.create! generate_finding_answer_from_mail(mail, user)
      else
        NotifierMailer.notify_action_not_found(mail.from, EMail.clean_answer(mail)).deliver_later
      end
    end

    private

      def extract_finding_id mail
        extract_subject(mail).slice /\[#(\d+)\]/, 1
      end

      def extract_subject mail
        mail.subject.present? ? mail.subject : '(no subject)'
      end

      def set_finding finding_id, user
        left_joins = scope_user_findings?(user) ? [:users] : []

        left_joins(left_joins).where(get_conditions(finding_id, user)).take
      end

      def scope_user_findings? user
        user.can_act_as_audited? && !user.committee?
      end

      def get_conditions finding_id, user
        conditions = { id: finding_id, final: false }

        if scope_user_findings? user
          user_ids = user.self_and_descendants.map(&:id) +
                     user.related_users_and_descendants.map(&:id)

          conditions[User.table_name] = { id: user_ids }
        end

        conditions
      end

      def generate_finding_answer_from_mail mail, user
        {
          answer: EMail.clean_answer(mail),
          user: user,
          imported: true
        }
      end

      def find_user mail, finding_id
        if exists?(finding_id)
          finding              = find finding_id
          Current.organization = finding.organization
          Current.group        = Current.organization.group

          User.list.find_by email: mail.from.first
        end
      end
  end
end
