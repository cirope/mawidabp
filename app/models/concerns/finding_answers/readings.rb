module FindingAnswers::Readings
  extend ActiveSupport::Concern

  included do
    after_save :create_current_user_reading, on: :create

    has_many :readings, as: :readable, dependent: :destroy
  end

  def reading_by user
    readings.where(user_id: user.id).take
  end

  private

    def create_current_user_reading
      readings.create! user: user, organization_id: finding.organization_id
    end
end
