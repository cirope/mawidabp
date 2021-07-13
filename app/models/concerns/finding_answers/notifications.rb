module FindingAnswers::Notifications
  extend ActiveSupport::Concern

  included do
    after_commit :send_notification_to_users

    attr_accessor :notify_users
  end

  # module ClassMethods
  #   def prueba
  #     Mail.defaults do
  #       retriever_method ENV['EMAIL_METHOD'].to_sym,  address:    ENV['EMAIL_SERVER'],
  #                                                     port:       ENV['EMAIL_PORT'],
  #                                                     user_name:  ENV['EMAIL_USER_NAME'],
  #                                                     password:   ENV['EMAIL_PASSWORD'],
  #                                                     enable_ssl: ENV['EMAIL_SSL'] != 'false'
  #     end

  #     Mail.first
  #   end
  # end

  private

    def send_notification_to_users
      if notify_users == true || notify_users == '1'
        users = finding.users - [user]

        if users.present? && answer.present?
          NotifierMailer.notify_new_finding_answer(users, self).deliver_later
        end
      end
    end
end
