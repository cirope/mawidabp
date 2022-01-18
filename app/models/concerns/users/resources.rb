module Users::Resources
  extend ActiveSupport::Concern

  included do
    has_many :resource_utilizations, -> {
      where resource_type: 'User'
    }, as: :resource, dependent: :destroy
  end
end
