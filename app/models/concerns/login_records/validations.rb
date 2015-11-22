module LoginRecords::Validations
  extend ActiveSupport::Concern

  included do
    validates :user, :organization, :start, presence: true
    validates_datetime :start, allow_nil: true, allow_blank: true
    validates_datetime :end, allow_nil: true, allow_blank: false,
      after: :start
  end
end
