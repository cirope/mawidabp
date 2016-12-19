module Users::Resources
  extend ActiveSupport::Concern

  included do
    belongs_to :resource
    has_many :resource_utilizations, as: :resource, dependent: :destroy
  end
end
