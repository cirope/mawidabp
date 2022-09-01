module Emails::Fetch
  extend ActiveSupport::Concern

  module ClassMethods
    def fetch
      reschedule_strategy.fetch if email_method?
    end

    def email_method?
      ENV['EMAIL_METHOD']
    end

    def clean_answer mail
      reschedule_strategy.clean_answer mail
    end

    private

      def reschedule_strategy
        if %w[pop3 imap].include? ENV['EMAIL_METHOD']
          EmailReceiverStrategies::ImapPopStrategy.new
        elsif %w[mgraph].include? ENV['EMAIL_METHOD']
          EmailReceiverStrategies::MGraphStrategy.new
        end
      end
  end
end
