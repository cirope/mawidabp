class ReviewUserAssignment < ActiveRecord::Base
  include ParameterSelector
  include Comparable

  has_paper_trail meta: { organization_id: -> { Organization.current_id } }

  # Constantes
  TYPES = {
    :audited => -1,
    :auditor => 0,
    :supervisor => 1,
    :manager => 2
  }

  # Callbacks
  before_validation :can_be_modified?
  before_destroy :can_be_modified?, :delete_user_in_all_review_findings
  before_save :check_user_modification

  # Restricciones
  validates :assignment_type, :user_id, :presence => true
  validates :assignment_type, :user_id, :review_id,
    :numericality => {:only_integer => true}, :allow_blank => true,
    :allow_nil => true
  validates :assignment_type, :inclusion => {:in => TYPES.values},
    :allow_blank => true, :allow_nil => true
  validates_each :user_id do |record, attr, value|
    # Recarga porque el cache se trae el usuario anterior aun cuando el user_id
    # ha cambiado
    user = User.find(value) if value && User.exists?(value)

    if user && record.review
      users = record.review.review_user_assignments.reject(
        &:marked_for_destruction?).map(&:user_id)

      record.errors.add attr, :taken if users.select { |u| u == value }.size > 1

      if (record.auditor? && !user.auditor?) ||
          (record.supervisor? && !user.supervisor?) ||
          (record.manager? && !user.supervisor?) ||
          (record.audited? && !user.can_act_as_audited?)
        record.errors.add attr, :invalid
      end
    end
  end

  # Relaciones
  belongs_to :review
  belongs_to :user

  def <=>(other)
    if self.review_id == other.review_id
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
    unless self.is_in_a_final_review? &&
        (self.changed? || self.marked_for_destruction?)
      true
    else
      msg = I18n.t('review.user_assignment.readonly')
      self.errors.add(:base, msg) unless self.errors.full_messages.include?(msg)

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
          'review_user_assignment.responsibility_modification.title',
          :review => self.review.try(:identification))
        notification_body = "#{Review.model_name.human} #{self.review.identification}"
        notification_content = [
          I18n.t(
            'review_user_assignment.responsibility_modification.old_responsible',
            :responsible => old_user.full_name_with_function),
          I18n.t(
            'review_user_assignment.responsibility_modification.new_responsible',
            :responsible => new_user.full_name_with_function)
        ]

        Notifier.changes_notification([new_user, old_user],
          :title => notification_title, :body => notification_body,
          :content => notification_content).deliver

        unless unconfirmed_findings.blank?
          Notifier.reassigned_findings_notification(new_user, old_user,
            unconfirmed_findings).deliver
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

  def delete_user_in_all_review_findings
    all_valid = false

    Finding.transaction do
      findings = self.user.findings.all_for_reallocation_with_review self.review
      all_valid = findings.all? do |finding|
        finding.users.delete self.user
        finding.valid?
      end

      unless all_valid
        self.errors.add(:base,
          I18n.t('review_user_assignment.cannot_be_destroyed'))
        raise ActiveRecord::Rollback
      end
    end

    if all_valid && !@cancel_notification &&
        (self.review.oportunities | self.review.weaknesses).size > 0
      title = I18n.t('review_user_assignment.responsibility_removed',
        :review => self.review.try(:identification))

      Notifier.changes_notification(self.user, :title => title).deliver
    end

    all_valid
  end

  def is_in_a_final_review?
    self.review.try(:has_final_review?)
  end

  # Definición dinámica de todos los métodos "tipo?"
  TYPES.each do |type, value|
    define_method("#{type}?") { self.assignment_type == value }
  end

  def type_text
    I18n.t "review.user_assignment.type_#{TYPES.invert[self.assignment_type]}"
  end
end
