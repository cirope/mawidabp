module ErrorRecords::Validations
  extend ActiveSupport::Concern

  included do
    ERRORS = { on_login: 1, on_password_change: 2, user_disabled: 3 }.freeze

    validates :error, inclusion: { in: ERRORS.values }
  end
end
