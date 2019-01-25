module Reviews::Interviews
  extend ActiveSupport::Concern

  included do
    has_many :opening_interviews, dependent: :destroy
    has_many :closing_interviews, dependent: :destroy
  end
end
