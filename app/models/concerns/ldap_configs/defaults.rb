module LdapConfigs::Defaults
  extend ActiveSupport::Concern

  included do
    after_initialize :nullify_empty_strings
  end

  private

  def nullify_empty_strings
    self.user     = nil if self.user.blank?
    self.password = nil if self.password.blank?
  end
end
