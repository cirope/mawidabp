module Users::Reassigns
  extend ActiveSupport::Concern

  included do
    attr_accessor :_unconfirmed_findings, :_reassigned_reviews, :_review_labels_from_findings
  end

  def reassign_to other, with_findings: false, with_reviews: false
    initialize_reassign_attributes

    Finding.transaction do
      reassign_pending_findings_to other if with_findings
      reassign_pending_reviews_to  other if with_reviews

      raise ActiveRecord::Rollback if reallocation_errors.present?

      notify_reassign_changes_to_me_and other
    end

    reallocation_errors.empty?
  end

  private

    def initialize_reassign_attributes
      self._unconfirmed_findings = []
      self._reassigned_reviews   = []
      self._organizations        = []
      self.reallocation_errors   = []
    end

    def reassign_pending_findings_to other
      findings_for_reallocation.each do |f|
        reassign_pending_finding f, other

        _unconfirmed_findings << f if f.unconfirmed?
        reallocation_errors   << finding_reallocation_errors_for(f) if f.invalid?
      end
    end

    def reassign_pending_finding finding, other
      old_fua = finding.finding_user_assignments.detect { |fua| fua.user == self }
      finding.avoid_changes_notification = true

      unless finding.users.include?(other)
        finding.finding_user_assignments.create user: other, process_owner: old_fua.process_owner
      end

      finding.finding_user_assignments.delete old_fua
    end

    def reassign_pending_reviews_to other
      review_user_assignments.each do |rua|
        unless rua.review.has_final_review?
          _unconfirmed_findings.concat unconfirmed_findings_in_review(rua.review)
          _reassigned_reviews << mini_review_description_for(rua.review)

          update_review_user_assignment rua, other
        end
      end
    end

    def unconfirmed_findings_in_review review
      findings_for(review).select do |f|
        f.unconfirmed? && !_unconfirmed_findings.include?(f)
      end
    end

    def update_review_user_assignment rua, other
      rua.notify_by_email = false

      unless rua.update user_id: other.id
        reallocation_errors << review_reallocation_errors_for(rua.review, rua.errors)
      end
    end

    def findings_for review
      review.weaknesses +
        review.oportunities +
        review.nonconformities +
        review.potential_nonconformities +
        review.fortresses
    end

    def notify_responsibility_changes_to_me_and other
      send_reassign_mail other if send_reassign_mail? other
    end

    def send_reassign_mail other
      Notifier.changes_notification(
        [other, self],
        title:         mail_title_for_reassign,
        body:          mail_body_from_reviews,
        content:       mail_content_for_reassign_to(other),
        organizations: affected_organizations_on_reassign_to(other)
      ).deliver
    end

    def send_reassign_mail? other
      initialize_review_labels_from other.findings.all_for_reallocation

      _review_labels_from_findings.size + _reassigned_reviews.size > 0
    end

    def initialize_review_labels_from findings
      self._review_labels_from_findings = findings.map do |f|
        mini_review_description_for f.review
      end

      self._review_labels_from_findings.uniq!
      self._review_labels_from_findings.sort!
    end

    def mail_title_for_reassign
      I18n.t 'user.responsibility_modification.title'
    end

    def mail_content_for_reassign_to other
      [
        I18n.t(
          'user.responsibility_modification.old_responsible',
          responsible: full_name_with_function
        ),
        I18n.t(
          'user.responsibility_modification.new_responsible',
          responsible: other.full_name_with_function
        )
      ]
    end

    def mail_body_from_reviews
      body =  mail_body_from_review_labels.to_s
      body << "\n\n" if body.present?
      body << mail_body_from_reassigned_reviews.to_s
    end

    def mail_body_from_review_labels
      if _review_labels_from_findings.present?
        I18n.t(
          'user.responsibility_modification.reassigned_to_findings_from_reviews',
          reviews: _review_labels_from_findings.to_sentence,
          count:   _review_labels_from_findings.size
        )
      end
    end

    def mail_body_from_reassigned_reviews
      if _reassigned_reviews.present?
        I18n.t(
          'user.responsibility_modification.reassigned_to_reviews',
          reviews: _reassigned_reviews.sort!.to_sentence,
          count:   _reassigned_reviews.size
        )
      end
    end

    def affected_organizations_on_reassign_to other
      _organizations | other.findings.all_for_reallocation.map(&:organization)
    end

    def notify_unconfirmed_findings_to other
      Notifier.changes_notification(
        other,
        title: mail_title_for_unconfirmed_findings,
        content: mail_content_for_unconfirmed_findings,
        notification: notification_for_unconfirmed_findings_to(other)
      ).deliver if _unconfirmed_findings.present?
    end

    def mail_title_for_unconfirmed_findings
      I18n.t 'user.unconfirmed_findings'
    end

    def mail_content_for_unconfirmed_findings
      content = ''

      _unconfirmed_findings.group_by(&:review).each do |r, findings|
        content << "*#{Review.model_name.human} #{r.identification}*"
        findings.each { |f| content << full_finding_description_for(f) }
        content << "\n\n"
      end

      content
    end

    def full_finding_description_for finding
      content = ''
      model = finding.class

      content << "\n* #{model.human_attribute_name('review_code')}: "
      content << "_#{finding.review_code}_"
      content << "\n** #{model.human_attribute_name('description')}: "
      content << "_#{finding.description}_"

      if finding.respond_to?(:risk_text)
        content << "\n** #{model.human_attribute_name('risk')}: "
        content << "_#{finding.risk_text}_"
      end

      content
    end

    def notification_for_unconfirmed_findings_to other
      Notification.create findings: _unconfirmed_findings, user: other
    end

    def notify_reassign_changes_to_me_and other
      notify_responsibility_changes_to_me_and other
      notify_unconfirmed_findings_to other
    end
end
