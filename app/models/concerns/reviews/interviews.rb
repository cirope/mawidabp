module Reviews::Interviews
  extend ActiveSupport::Concern

  included do
    has_one :opening_interview, dependent: :destroy
    has_one :closing_interview, dependent: :destroy
  end
end
