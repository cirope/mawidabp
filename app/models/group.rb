class Group < ActiveRecord::Base
  include Trimmer

  trimmed_fields :name, :admin_email, :admin_hash

  has_paper_trail

  # Atributos no persistentes
  attr_accessor :send_notification_email

  # Callbacks
  after_save :send_notification_if_necesary

  # Restricciones
  validates_presence_of :name, :admin_email
  validates_length_of :name, :admin_hash, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  validates_length_of :admin_email, :maximum => 100, :allow_nil => true,
    :allow_blank => true
  validates_uniqueness_of :name, :admin_email, :case_sensitive => false
  validates_format_of :admin_email, :with => EMAIL_REGEXP, :allow_nil => true,
    :allow_blank => true

  # Relaciones
  has_many :organizations, :dependent => :destroy, :order => 'name ASC',
    :after_add => :mark_for_parameters_and_role_creation

  accepts_nested_attributes_for :organizations, :allow_destroy => true
  
  def initialize(attributes = nil)
    super(attributes)
    
    self.send_notification_email = true if self.send_notification_email.nil?
    
    if self.send_notification_email
      self.admin_hash = UUIDTools::UUID.random_create.to_s
    end
  end

  def send_notification_if_necesary
    unless self.send_notification_email.blank?
      unless self.admin_hash
        self.send_notification_email = false

        self.update_attribute :admin_hash, UUIDTools::UUID.random_create.to_s

        self.send_notification_email = true
      end

      Notifier.deliver_group_welcome_email(self)
    end
  end

  def mark_for_parameters_and_role_creation(organization)
    if organization.new_record?
      organization.must_create_parameters = true
      organization.must_create_roles = true
    end
  end
end