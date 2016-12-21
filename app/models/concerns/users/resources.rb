module Users::Resources
  extend ActiveSupport::Concern

  included do
    has_many :resource_utilizations, as: :resource, dependent: :destroy
  end
end
