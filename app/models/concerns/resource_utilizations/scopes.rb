module ResourceUtilizations::Scopes
  extend ActiveSupport::Concern

  included do
    scope :human, -> { where resource_type: 'User' }

    scope :material, -> { where resource_type: 'Resource' }
  end
end
