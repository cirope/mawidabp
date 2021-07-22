module Emails::Fetch
  extend ActiveSupport::Concern

  module ClassMethods
    def fetch
      if email_method?
        config

        Mail.all.each do |mail|
          begin
            Finding.receive_mail mail
          rescue Exception => exception
            log exception, mail
          end
        end
      end
    end

    private

      def email_method?
        ENV['EMAIL_METHOD']
      end

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

      def log exception, mail
        logger = Logger.new 'log/mailman.log'

        logger.error "Exception occurred while receiving message:\n#{mail}"
        logger.error [exception, *exception.backtrace].join("\n")
      end
  end
end
