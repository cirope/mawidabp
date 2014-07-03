class LoginRecord < ActiveRecord::Base
  include Auditable
  include ParameterSelector
  include LoginRecords::Defaults
  include LoginRecords::Validations
  include LoginRecords::Scopes
  include LoginRecords::Search

  attr_accessor :request

  belongs_to :user
  belongs_to :organization

  def to_s
    user
  end
end
