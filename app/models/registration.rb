class Registration
  include ActiveModel::Model
  include ActiveModel::Validations

  include Users::BaseValidations
  include Registrations::Persistence
  include Registrations::Validations

  attr_accessor :organization_name, :user, :name, :last_name, :email
end
