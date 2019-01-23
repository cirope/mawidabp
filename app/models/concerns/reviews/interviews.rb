module Reviews::Interviews
  extend ActiveSupport::Concern

  included do
    has_many :opening_interviews, dependent: :destroy
  end
end
