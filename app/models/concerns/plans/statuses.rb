module Plans::Statuses
  extend ActiveSupport::Concern

  included do
    enum status: {
      draft:    'draft',
      approved: 'approved'
    }
  end
end
