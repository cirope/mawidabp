# require 'app/extension/extended_email_reply_parsers/spanish_parser'

module Findings::FindingAnswersGenerator
  extend ActiveSupport::Concern

  module ClassMethods
    def receive_finding_answers
      config

      Mail.all.each do |mail|
        begin
          receive_mail mail
        rescue Exception => exception
          log exception, mail
        end
      end
    end

    private

    def receive_mail mail
      finding_id = extract_finding_id mail

      if finding_id && exists?(finding_id)
        find(finding_id).finding_answers.create generate_finding_answer_from_mail(mail)
      else
        NotifierMailer.notify_not_added_answer(mail.from, extract_answer(mail)).deliver_later
      end
    end

    def config
      Mail.defaults do
        retriever_method ENV['EMAIL_METHOD'].to_sym,  address:    ENV['EMAIL_SERVER'],
                                                      port:       ENV['EMAIL_PORT'],
                                                      user_name:  ENV['EMAIL_USER_NAME'],
                                                      password:   ENV['EMAIL_PASSWORD'],
                                                      enable_ssl: ENV['EMAIL_SSL'] != 'false'
      end
    end

    def log exception, mail
      logger = Logger.new 'log/mailman.log'

      logger.error "Exception occurred while receiving message:\n#{mail}"
      logger.error [exception, *exception.backtrace].join("\n")
    end

    def extract_finding_id mail
      extract_subject(mail).slice(/\[#(\d+)\]/, 1)
    end

    def extract_subject mail
      mail.subject.present? ? mail.subject : '(no subject)'
    end

    def generate_finding_answer_from_mail mail
      {
        answer: extract_answer(mail),
        user: find_user(mail),
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
