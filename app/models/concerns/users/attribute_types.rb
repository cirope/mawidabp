module Users::AttributeTypes
  extend ActiveSupport::Concern

  included do
    attribute :password_changed, :date
    attribute :enable, :boolean
    attribute :logged_in, :boolean
    attribute :group_admin, :boolean
    attribute :hidden, :boolean
  end
end
