class ErrorRecord < ActiveRecord::Base
  include Auditable
  include ParameterSelector
  include Associations::DestroyPaperTrail
  include ErrorRecords::Search
  include ErrorRecords::Defaults
  include ErrorRecords::Validations
  include ErrorRecords::Scopes

  attr_accessor :request, :user_name, :error_type

  belongs_to :user
  belongs_to :organization

  def to_s
    user ? user.user : I18n.t('error_records.void_user')
  end

  def error_text
    I18n.t("error_records.error_#{ERRORS.invert[error]}")
  end
end
