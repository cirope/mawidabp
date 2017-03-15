module ResourceUtilizations::Resources
  extend ActiveSupport::Concern

  included do
    belongs_to :resource, polymorphic: true

    belongs_to :user, -> {
      where resource_utilizations: { resource_type: 'User' }
    }, foreign_key: 'resource_id', optional: true
  end
end
