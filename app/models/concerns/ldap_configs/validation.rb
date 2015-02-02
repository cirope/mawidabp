module LdapConfigs::Validation
  extend ActiveSupport::Concern

  included do
    validates :hostname, :port, :basedn, :login_mask, :username_attribute,
      :name_attribute, :last_name_attribute, :email_attribute,
      :roles_attribute, :organization, presence: true
    validates :hostname, :basedn, :login_mask, :username_attribute,
      :name_attribute, :last_name_attribute, :email_attribute,
      :roles_attribute, :organization, length: { maximum: 255 }
    validates :port, numericality: { only_integer: true, greater_than: 0, less_than: 65536 }
    validates :basedn, format: /\A(\w+=\w+)(,\w+=\w+)*\z/
    validates :username_attribute, :name_attribute, :last_name_attribute,
      :email_attribute, :function_attribute, :roles_attribute,
      :manager_attribute, format: /\A\w+\z/, allow_blank: true
  end
end
