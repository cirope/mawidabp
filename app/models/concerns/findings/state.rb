module Findings::State
  extend ActiveSupport::Concern

  included do
    STATUS                      = status
    STATUS_TRANSITIONS          = status_transitions
    PENDING_STATUS              = pending_status
    EXCLUDE_FROM_REPORTS_STATUS = exclude_from_reports_status

    define_state_scopes
    define_state_methods
  end

  module ClassMethods
    private

      def status
        {
          confirmed:            -3,
          unconfirmed:          -2,
          unanswered:           -1,
          being_implemented:    0,
          implemented:          1,
          implemented_audited:  2,
          assumed_risk:         3,
          notify:               4,
          incomplete:           5,
          repeated:             6,
          revoked:              7
        }.with_indifferent_access.freeze
      end

      def status_transitions
        {
          confirmed:            confirmed_transitions,
          unconfirmed:          unconfirmed_transitions,
          unanswered:           unanswered_transitions,
          being_implemented:    being_implemented_transitions,
          implemented:          implemented_transitions,
          implemented_audited:  implemented_audited_transitions,
          assumed_risk:         assumed_risk_transitions,
          notify:               notify_transitions,
          incomplete:           incomplete_transitions,
          repeated:             repeated_transitions,
          revoked:              revoked_transitions
        }.with_indifferent_access.freeze
      end

      def pending_status
        [
          STATUS[:being_implemented], STATUS[:notify], STATUS[:implemented],
          STATUS[:unconfirmed], STATUS[:confirmed], STATUS[:unanswered],
          STATUS[:incomplete]
        ]
      end

      def define_state_scopes
        scope :revoked,     -> { where     state: STATUS[:revoked] }
        scope :not_revoked, -> { where.not state: STATUS[:revoked] }
        scope :with_pending_status, -> { where state: visible_pending_status }
        scope :with_pending_status_for_report, -> { where state: report_pending_status }
      end

      def define_state_methods
        STATUS.each do |type, value|
          define_method("#{type}?")     { state     == value }
          define_method("was_#{type}?") { state_was == value }
        end
      end

      def exclude_from_reports_status
        [:unconfirmed, :confirmed, :notify, :incomplete, :repeated, :revoked]
      end

      def confirmed_transitions
        [:confirmed, :unanswered, :being_implemented, :implemented, :implemented_audited, :assumed_risk, :revoked]
      end

      def unconfirmed_transitions
        [:unconfirmed, :confirmed, :unanswered]
      end

      def unanswered_transitions
        [:unanswered, :being_implemented, :implemented, :implemented_audited, :assumed_risk, :revoked]
      end

      def being_implemented_transitions
        [:being_implemented, :implemented, :implemented_audited, :assumed_risk, :repeated, :revoked]
      end

      def implemented_transitions
        [:implemented, :being_implemented, :implemented_audited, :assumed_risk, :repeated, :revoked]
      end

      def implemented_audited_transitions
        [:implemented_audited]
      end

      def assumed_risk_transitions
        [:assumed_risk]
      end

      def notify_transitions
        [:notify, :incomplete, :being_implemented, :implemented, :implemented_audited, :assumed_risk, :revoked]
      end

      def incomplete_transitions
        [:incomplete, :notify, :being_implemented, :implemented, :implemented_audited, :assumed_risk, :revoked]
      end

      def repeated_transitions
        [:repeated]
      end

      def revoked_transitions
        [:revoked]
      end

      def visible_pending_status
        PENDING_STATUS - [STATUS[:incomplete]]
      end

      def report_pending_status
        STATUS.except(*EXCLUDE_FROM_REPORTS_STATUS).values & PENDING_STATUS
      end
  end

  def next_status_list state = nil
    state_key    = STATUS.invert[state || self.state]
    allowed_keys = STATUS_TRANSITIONS[state_key]

    STATUS.select { |k,| allowed_keys.include? k.to_sym }
  end

  def status_change_history
    findings_with_status_changed = versions_with_state_change

    unless findings_with_status_changed.last.try(:state) == state
      findings_with_status_changed << self
    end

    findings_with_status_changed
  end

  def state_text
    state ? I18n.t("finding.status_#{STATUS.invert[state]}") : '-'
  end

  private

    def versions_with_state_change
      last_state = nil

      versions.each_with_object([]) do |version, result|
        finding = version.reify has_one: false

        if finding && finding.state != last_state
          last_state = finding.state

          if u_id = version.previous.try(:whodunnit)
            finding.user_who_make_it = User.find u_id
          end

          result << finding
        end
      end
    end
end
