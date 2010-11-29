class FindingAnswer < ActiveRecord::Base
  include ParameterSelector

  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Callbacks
  after_create :send_notification_to_users

  # Atributos no persistentes
  attr_accessor :notify_users

  # Restricciones para la actualización de algunos parámetros
  attr_readonly :answer_type, :answer, :auditor_comments, :file_model_id,
    :finding_id, :user_id, :created_at

  # Restricciones
  validates_presence_of :finding_id, :answer_type, :answer
  validates_numericality_of :finding_id, :user_id, :file_model_id, :answer_type,
    :only_integer => true, :allow_nil => true, :allow_blank => true
  
  # Relaciones
  belongs_to :finding
  belongs_to :user
  belongs_to :file_model, :dependent => :destroy

  accepts_nested_attributes_for :file_model, :allow_destroy => true

  def answer_type_text
    answer_types = self.get_parameter(:admin_finding_answers_types)
    answer_type = answer_types.detect { |at| at.last == self.answer_type }

    answer_type ? answer_type.first : ''
  end

  def send_notification_to_users
    if self.notify_users == true || self.notify_users == '1'
      users = self.finding.users - [self.user]

      Notifier.notify_new_finding_answer(users,
        (self unless users.blank?)).deliver
    end
  end
end