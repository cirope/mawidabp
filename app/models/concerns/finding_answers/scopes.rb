module FindingAnswers::Scopes
  extend ActiveSupport::Concern

  included do
    scope :latest, -> { reorder(created_at: :desc).limit 5 }
  end

  module ClassMethods
    def readed_by user
      joins(:readings).where readings: { user_id: user.id }
    end
  end
end
