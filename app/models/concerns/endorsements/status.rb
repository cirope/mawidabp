module Endorsements::Status
  extend ActiveSupport::Concern

  included do
    enum status: {
      pending:  'pending',
      approved: 'approved',
      rejected: 'rejected'
    }
  end
end
