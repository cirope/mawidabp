# frozen_string_literal: true

class EmailReceiverStrategies::EmailReceiverStrategy
  def initialize
    raise 'Cannot initialize abstract EmailReceiverStrategy'
  end

  def fetch
    raise NotImplementedError
  end

  def clean_answer mail
    raise NotImplementedError
  end

  private

    def log exception, mail
      logger = Logger.new 'log/mailman.log'

      logger.error "Exception occurred while receiving message:\n#{mail}"
      logger.error [exception, *exception.backtrace].join("\n")
    end
end
