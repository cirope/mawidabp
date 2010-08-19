class ReviewUserAssignment < ActiveRecord::Base
  include ParameterSelector
  include Comparable

  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Constantes
  TYPES = {
    :audited => -1,
    :auditor => 0,
    :supervisor => 1,
    :manager => 2
  }

  # Atributos no persistentes
  attr_accessor_with_default :notify_by_email, true

  # Callbacks
  before_validation :can_be_modified?
  before_destroy :can_be_modified?, :delete_user_in_all_review_findings
  before_save :check_user_modification
  
  # Restricciones
  validates_presence_of :assignment_type, :user_id
  validates_numericality_of :assignment_type, :user_id, :review_id,
    :only_integer => true, :allow_blank => true, :allow_nil => true
  validates_inclusion_of :assignment_type, :in => TYPES.values,
    :allow_blank => true, :allow_nil => true
  validates_each :user do |record, attr, value|
    review = record.review
    user = User.find(record.user_id) if User.exists?(record.user_id)

    # Recarga porque el cache se trae el usuario anterior aun cuando el user_id
    # ha cambiado
    unless user.blank?
      if review
        supervisor_count, manager_count, user_count = 0, 0, 0

        review.review_user_assignments.each do |rua|
          unless rua.marked_for_destruction?
            another_record = (!record.new_record? && rua.id != record.id) ||
                (record.new_record? && rua.object_id != record.object_id)

            supervisor_count += 1 if rua.supervisor? && another_record
            manager_count += 1 if rua.manager? && another_record
            user_count += 1 if rua.user_id == record.user_id && another_record
          end
        end

        record.errors.add attr, :taken if user_count > 0

        if (supervisor_count > 0 && record.supervisor?) ||
            (manager_count > 0 && record.manager?)
          record.errors.add attr, :role_taken
        end

        if (record.auditor? && !user.auditor?) ||
            (record.supervisor? && !user.supervisor?) ||
            (record.manager? && !user.manager?) ||
            (record.audited? && !user.can_act_as_audited?)
          record.errors.add attr, :invalid
        end
      end
    end
  end

  # Relaciones
  belongs_to :review
  belongs_to :user

  def <=>(other)
    self.user_id <=> other.user_id
  end

  def can_be_modified?
    unless self.is_in_a_final_review? &&
        (self.changed? || self.marked_for_destruction?)
      true
    else
      msg = I18n.t(:'review.user_assignment.readonly')
      self.errors.add_to_base msg unless self.errors.full_messages.include?(msg)

      false
    end
  end

  def check_user_modification
    if self.user_id_changed? && self.user_id_was && self.notify_by_email
      old_user = User.find(self.user_id_was)
      new_user = User.find(self.user_id)
      unconfirmed_findings = []
      transfered = false

      Finding.transaction do
        findings = old_user.findings.all_for_reallocation_with_review(
          self.review)

        transfered = findings.all? do |finding|
          finding.avoid_changes_notification = true
          finding.users << new_user
          finding.users.delete old_user
          unconfirmed_findings << finding if finding.unconfirmed?

          finding.valid?
        end

        unless transfered
          self.errors.add :user_id, :invalid

          raise ActiveRecord::Rollback
        end
      end

      if transfered
        notification_title = I18n.t(
          :'review_user_assignment.responsibility_modification.title',
          :review => self.review.try(:identification))
        notification_body = "#{Review.human_name} #{self.review.identification}"
        notification_content = [
          I18n.t(
            :'review_user_assignment.responsibility_modification.old_responsible',
            :responsible => old_user.full_name_with_function),
          I18n.t(
            :'review_user_assignment.responsibility_modification.new_responsible',
            :responsible => new_user.full_name_with_function)
        ]

        Notifier.deliver_changes_notification([new_user, old_user],
          :title => notification_title, :body => notification_body,
          :content => notification_content)

        unless unconfirmed_findings.blank?
          Notifier.deliver_reassigned_findings_notification(new_user, old_user,
            unconfirmed_findings)
        end
      else
        self.errors.add_to_base(
          I18n.t(:'review_user_assignment.cannot_be_reassigned'))
      end

      transfered
    end
  end

  def destroy_without_notification
    @cancel_notification = true

    self.destroy
  end

  def delete_user_in_all_review_findings
    all_valid = false
    
    Finding.transaction do
      findings = self.user.findings.all_for_reallocation_with_review self.review
      all_valid = findings.all? do |finding|
        finding.users.delete self.user
        finding.valid?
      end
      
      unless all_valid
        self.errors.add_to_base(
          I18n.t(:'review_user_assignment.cannot_be_destroyed'))
        raise ActiveRecord::Rollback
      end
    end

    if all_valid && !@cancel_notification
      title = I18n.t(:'review_user_assignment.responsibility_removed',
        :review => self.review.try(:identification))

      Notifier.deliver_changes_notification self.user, :title => title
    end

    all_valid
  end

  def is_in_a_final_review?
    self.review.try(:has_final_review?)
  end

  # Definición dinámica de todos los métodos "tipo?"
  TYPES.each do |type, value|
    define_method("#{type}?".to_sym) { self.assignment_type == value }
  end

  def type_text
    I18n.t "review.user_assignment.type_#{TYPES.invert[self.assignment_type]}"
  end
end