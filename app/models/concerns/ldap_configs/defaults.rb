module LdapConfigs::Defaults
  extend ActiveSupport::Concern

  included do
    after_initialize :nullify_empty_strings
  end

  private

  def nullify_empty_strings
    self.user     = nil if user.blank?
    self.password = nil if password.blank?
  end
end
