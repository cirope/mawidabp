module Users::Name
  extend ActiveSupport::Concern

  included do
    alias_method :resource_name, :full_name
    alias_method :label, :full_name_with_function
  end

  def informal_name from = nil
    version = version_of from

    [version.name, version.last_name].compact.map(&:strip).join(' ')
  end

  def full_name from = nil
    version = version_of from

    "#{version.last_name}, #{version.name}"
  end

  def full_name_with_user from = nil
    version = version_of from

    "#{version.full_name} (#{version.user}) #{version.string_to_append_if_disable}"
  end

  def full_name_with_function from = nil
    version = version_of from

    "#{version.full_name}#{version.string_to_append_if_function}#{version.string_to_append_if_disable}"
  end

  def string_to_append_if_disable
    " - (#{I18n.t('user.disabled')})" unless enable? || full_name.blank?
  end

  def string_to_append_if_function
    " (#{function})" unless function.blank? || full_name.blank?
  end
end
