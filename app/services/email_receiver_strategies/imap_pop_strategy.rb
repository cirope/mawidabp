# frozen_string_literal: true

class EmailReceiverStrategies::ImapPopStrategy < EmailReceiverStrategies::EmailReceiverStrategy
  def initialize; end;

  def fetch
    config

    Mail.all.each do |mail|
      begin
        Finding.receive_mail mail
      rescue Exception => exception
        log exception, mail
      end
    end
  end

  def clean_answer mail
    charset_mail = mail.text_part.charset
    body         = mail.text_part.decoded
    body         = body.force_encoding(charset_mail).encode('UTF-8') if charset_mail
    regex        = Regexp.new(ENV['REGEX_REPLY_EMAIL'], Regexp::MULTILINE)
    clean_answer = body.split regex

    clean_answer.present? ? clean_answer.first : '-'
  end

  private

    def config
      Mail.defaults do
        email_method = ENV['EMAIL_METHOD'].to_sym

        retriever_method email_method, address:    ENV['EMAIL_SERVER'],
                                       port:       ENV['EMAIL_PORT'],
                                       user_name:  ENV['EMAIL_USER_NAME'],
                                       password:   ENV['EMAIL_PASSWORD'],
                                       enable_ssl: ENV['EMAIL_SSL'] != 'false'
      end
    end
end
