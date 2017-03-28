module Users::Releases
  extend ActiveSupport::Concern

  included do
    attr_accessor :_items_for_notification, :_organizations
  end

  def release_pendings with_findings: false, with_reviews: false
    initialize_release_attributes

    Finding.transaction do
      release_pending_findings if with_findings
      release_pending_reviews  if with_reviews

      if has_reallocation_errors?
        errors.add :base, 'Invalid release'
        raise ActiveRecord::Rollback
      end

      notify_release_changes
    end

    reallocation_errors.empty?
  end

  private

    def initialize_release_attributes
      self._organizations          = []
      self._items_for_notification = []
      self.reallocation_errors     = []
    end

    def findings_for_reallocation
      findings.list.all_for_reallocation
    end

    def release_pending_findings
      findings_for_reallocation.each do |f|
        f.avoid_changes_notification = true
        f.users.delete self
        _items_for_notification << finding_description_for(f)
        _organizations          << f.organization
        reallocation_errors     << finding_reallocation_errors_for(f) if f.invalid?
      end
    end

    def release_pending_reviews
      review_user_assignments.each do |rua|
        unless rua.review.has_final_review?
          _items_for_notification << review_description_for(rua.review)
          _organizations          << rua.review.organization

          unless rua.destroy_without_notification
            reallocation_errors << review_reallocation_errors_for(rua.review, rua.errors)
          end
        end
      end
    end

    def notify_release_changes
      if reallocation_errors.empty? && _items_for_notification.present?
        Notifier.changes_notification(
          self,
          title: I18n.t('user.responsibility_release.title'),
          content: _items_for_notification,
          organizations: _organizations
        ).deliver_later
      end
    end

    def has_reallocation_errors?
      errors.add :base, I18n.t('user.user_release_failed') if reallocation_errors.present?
    end

    def finding_reallocation_errors_for finding
      [finding_description_for(finding), finding.errors.full_messages]
    end

    def finding_description_for finding
      [
        finding.class.model_name.human,
        "*#{[finding.review_code.strip, finding.title && finding.title.strip].compact.join(' - ')}*",
        "(#{Review.model_name.human} *#{finding.review.identification.strip}*)"
      ].join ' '
    end

    def review_reallocation_errors_for review, errors
      [review_description_for(review), errors.full_messages]
    end

    def review_description_for review
      "#{Review.model_name.human}: #{mini_review_description_for review}"
    end

    def mini_review_description_for review
      "*#{review.identification.strip}*"
    end
end
