class ReviewUserAssignment < ApplicationRecord
  include Auditable
  include ParameterSelector
  include Comparable
  include ReviewUserAssignments::AttributeTypes
  include ReviewUserAssignments::DestroyCallbacks
  include ReviewUserAssignments::Scopes

  # Constantes
  TYPES = {
    viewer: -2,
    audited: -1,
    auditor: 0,
    supervisor: 1,
    manager: 2,
    responsible: 3
  }

  AUDIT_TEAM_TYPES = [
    TYPES[:auditor],
    TYPES[:supervisor],
    TYPES[:manager],
    TYPES[:responsible]
  ]

  # Callbacks
  before_validation :check_if_can_modified
  before_destroy :check_if_can_modified
  before_save :check_user_modification

  # Restricciones
  validates :assignment_type, :user_id, presence: true
  validates :assignment_type, :user_id, :review_id,
    numericality: { only_integer: true },
    allow_blank: true, allow_nil: true
  validates :assignment_type, inclusion: { in: TYPES.values },
    allow_blank: true, allow_nil: true
  validates_each :user_id do |record, attr, value|
    # Recarga porque el cache se trae el usuario anterior aun cuando el user_id
    # ha cambiado
    user = User.find_by(id: value)

    if user && record.review
      others = record.review.review_user_assignments.map do |rua|
        if !rua.marked_for_destruction? && rua.object_id != record.object_id
          rua.user_id
        end
      end

      if others.reverse.compact.select { |u| u == value }.size > 1
        record.errors.add attr, :taken
      end

      if (record.auditor? && !user.auditor?) ||
          (record.supervisor? && !user.supervisor?) ||
          (record.manager? && (!user.supervisor? && !user.manager?)) ||
          (record.responsible? && (!user.supervisor? && !user.manager?)) ||
          (record.audited? && !user.can_act_as_audited?)
        record.errors.add attr, :invalid
      end
    end
  end

  # Relaciones
  belongs_to :review
  belongs_to :user

  def <=>(other)
    if other.kind_of?(ReviewUserAssignment) && self.review_id == other.review_id
      self.user_id <=> other.user_id
    else
      -1
    end
  end

  def ==(other)
    other.kind_of?(ReviewUserAssignment) && other.id &&
      (self.id == other.id || (self <=> other) == 0)
  end

  def notify_by_email
    unless @__nbe_first_access
      @notify_by_email = true
      @__nbe_first_access = true
    end

    @notify_by_email
  end

  def notify_by_email=(notify_by_email)
    @__nbe_first_access = true

    @notify_by_email = notify_by_email
  end

  def can_be_modified?
    if self.is_in_a_final_review? && (self.changed? || self.marked_for_destruction?)
      msg = I18n.t('review.user_assignment.readonly')
      self.errors.add(:base, msg) unless self.errors.full_messages.include?(msg)

      false
    else
      true
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
          fua = finding.finding_user_assignments.detect do |fua|
            fua.user_id == old_user.id
          end

          finding.avoid_changes_notification = true

          finding.finding_user_assignments.build user_id: new_user.id
          fua.mark_for_destruction

          unconfirmed_findings << finding if finding.unconfirmed?

          finding.save
        end

        unless transfered
          self.errors.add :user_id, :invalid

          raise ActiveRecord::Rollback
        end
      end

      if transfered
        if unconfirmed_findings.present?
          NotifierMailer.reassigned_findings_notification(
            new_user, old_user, unconfirmed_findings
          ).deliver_later
        end
      else
        self.errors.add :base,
          I18n.t('review_user_assignment.cannot_be_reassigned')
      end

      transfered
    end
  end

  def destroy_without_notification
    @cancel_notification = true

    self.destroy
  end

  def is_in_a_final_review?
    self.review.try(:has_final_review?)
  end

  # Definición dinámica de todos los métodos "tipo?"
  TYPES.each do |type, value|
    define_method("#{type}?") { self.assignment_type == value }
  end

  def in_audit_team?
    AUDIT_TEAM_TYPES.include? assignment_type
  end

  def type_text
    I18n.t "review.user_assignment.type_#{TYPES.invert[self.assignment_type]}"
  end

  private

    def check_if_can_modified
      throw :abort unless can_be_modified?
    end
end
