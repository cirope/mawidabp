module Findings::ProcessEmail
  extend ActiveSupport::Concern

  module ClassMethods
    def receive_mail mail
      finding_id = extract_finding_id(mail)
      user       = find_user mail if finding_id
      finding    = set_finding(finding_id, user) if user

      if finding
        finding.finding_answers.create generate_finding_answer_from_mail(mail, user)
      else
        NotifierMailer.notify_action_not_found(mail.from, extract_answer(mail)).deliver_later
      end
    end

    private

      def extract_finding_id mail
        extract_subject(mail).slice(/\[#(\d+)\]/, 1)
      end

      def extract_subject mail
        mail.subject.present? ? mail.subject : '(no subject)'
      end

      def set_finding finding_id, user
        if exists? finding_id
          finding              = find finding_id
          Current.organization = finding.organization
          Current.group        = Current.organization.group

          left_joins = scope_user_findings?(user) ? [:users] : []

          left_joins(left_joins).where(get_conditions(finding_id, user)).take
        end
      end

      def scope_user_findings? user
        !Current.organization.corporate &&
          user.can_act_as_audited? &&
          !user.committee?
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
          answer: extract_answer(mail),
          user: user,
          imported: true
        }
      end

      def extract_answer mail
        charset_mail = mail.text_part.charset
        body         = mail.text_part.decoded
        body         = body.force_encoding(charset_mail).encode('UTF-8') if charset_mail
        regex        = Regexp.new(ENV['REGEX_REPLY_EMAIL'], Regexp::MULTILINE)
        clean_answer = body.split regex

        clean_answer.present? ? clean_answer.first : '-'
      end

      def find_user mail
        User.find_by email: mail.from.first
      end
  end
end
