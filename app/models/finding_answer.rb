class FindingAnswer < ActiveRecord::Base
  include ParameterSelector

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  # Callbacks
  after_create :send_notification_to_users

  # Atributos no persistentes
  attr_accessor :notify_users

  # Restricciones para la actualización de algunos parámetros
  attr_readonly :answer, :file_model_id, :finding_id, :user_id, :created_at

  # Restricciones
  validates :finding_id, :answer, :presence => true
  validates :finding_id, :user_id, :file_model_id,
    :numericality => {:only_integer => true}, :allow_nil => true,
    :allow_blank => true
  validates_date :commitment_date, :allow_nil => true, :allow_blank => true
  validates :commitment_date, :presence => true, :if => lambda { |fa|
    fa.user.try(:can_act_as_audited?) && fa.finding.try(:pending?) &&
      fa.finding.commitment_date.blank?
  }

  # Relaciones
  belongs_to :finding
  belongs_to :user, -> { where("#{User.quoted_table_name}.#{User.qcn 'hidden'}" => [true, false]) }
  belongs_to :file_model, :dependent => :destroy

  accepts_nested_attributes_for :file_model, :allow_destroy => true

  def initialize(attributes = nil, options = {})
    super(attributes, options)

    self.notify_users = true if self.notify_users.nil?
  end

  def send_notification_to_users
    if self.notify_users == true || self.notify_users == '1'
      users = self.finding.users - [self.user]

      if !users.blank? && !self.answer.blank?
        NotifierMailer.notify_new_finding_answer(users, self).deliver_later
      end
    end
  end
end
