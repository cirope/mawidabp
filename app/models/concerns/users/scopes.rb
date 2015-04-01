module Users::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> {
      includes(:organizations).where(
        organizations: { id: Organization.current_id }
      ).references(:organizations)
    }
    scope :all_with_findings_for_notification, -> {
      includes(
        finding_user_assignments: :raw_finding
      ).references(:findings).where(
        findings: { state: Finding::STATUS[:notify], final: false }
      ).order([
        "#{quoted_table_name}.#{qcn('last_name')} ASC",
        "#{quoted_table_name}.#{qcn('name')} ASC"
      ])
    }
    scope :not_hidden, -> { where hidden: false }
  end

  module ClassMethods
    def with_valid_confirmation_hash(confirmation_hash)
      where(
        [
          'change_password_hash = :confirmation_hash', 'hash_changed > :time'
        ].join(' AND '),
        {
          confirmation_hash: confirmation_hash,
          time: BLANK_PASSWORD_STALE_DAYS.days.ago,
        }
      )
    end
  end
end
