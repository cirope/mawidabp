class Organization < ActiveRecord::Base
  include Auditable
  include Comparable
  include ParameterSelector
  include Trimmer
  include Organizations::Current
  include Organizations::Group
  include Organizations::Images
  include Organizations::LdapConfigs
  include Organizations::Parameters
  include Organizations::Roles
  include Organizations::Scopes
  include Organizations::Setting
  include Associations::DestroyPaperTrail
  include Associations::DestroyInBatches
  include Organizations::Validations

  trimmed_fields :name, :prefix

  has_many :benefits, dependent: :destroy
  has_many :best_practices, dependent: :destroy
  has_many :business_unit_types, -> { order(name: :asc) }, dependent: :destroy
  has_many :error_records, dependent: :destroy
  has_many :login_records, dependent: :destroy
  has_many :periods, dependent: :destroy
  has_many :polls, dependent: :destroy
  has_many :questionnaires, dependent: :destroy
  has_many :users, through: :organization_roles, dependent: :destroy
  has_many :e_mails, dependent: :destroy
  has_many :resource_classes, dependent: :destroy
  has_many :version_organizations, dependent: :destroy, class_name: 'PaperTrail::Version',
    foreign_key: 'organization_id'

  accepts_nested_attributes_for :image_model, allow_destroy: true,
    reject_if: ->(attributes) { attributes['image'].blank? }

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
