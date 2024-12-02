module Plans::Status
  extend ActiveSupport::Concern

  included do
    enum status: {
      draft:    'draft',
      approved: 'approved'
    }
  end
end
