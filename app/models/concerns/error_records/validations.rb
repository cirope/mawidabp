module ErrorRecords::Validations
  extend ActiveSupport::Concern
  include ErrorRecords::Constants

  included do
    validates :error, inclusion: { in: ERRORS.values }
  end
end
