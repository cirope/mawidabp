class Organization < ActiveRecord::Base
  include Auditable
  include Comparable
  include ParameterSelector
  include Trimmer
  include Organizations::Current
  include Organizations::DestroyValidation
  include Organizations::Group
  include Organizations::Images
  include Organizations::Parameters
  include Organizations::Roles
  include Organizations::Scopes
  include Organizations::Setting
  include Organizations::Validations

  trimmed_fields :name, :prefix

  has_many :best_practices, dependent: :destroy
  has_many :business_unit_types, -> { order('name ASC') }, dependent: :destroy
  has_many :error_records, dependent: :destroy
  has_many :login_records, dependent: :destroy
  has_many :periods, dependent: :destroy
  has_many :polls, dependent: :destroy
  has_many :questionnaires, dependent: :destroy
  has_many :resource_classes, dependent: :destroy
  has_many :users, -> { readonly }, through: :organization_roles
  has_many :work_papers, dependent: :destroy

  def to_s
    name
  end

  def <=>(other)
    if other.kind_of?(Organization)
      prefix <=> other.prefix
    else
      -1
    end
  end
end
