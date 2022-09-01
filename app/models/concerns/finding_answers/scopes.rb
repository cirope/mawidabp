module FindingAnswers::Scopes
  extend ActiveSupport::Concern

  module ClassMethods
    def readed_by user
      joins(:readings).where readings: { user_id: user.id }
    end
  end
end
