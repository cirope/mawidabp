module Findings::State
  extend ActiveSupport::Concern

  included do
    STATUS                               = status
    STATUS_TRANSITIONS                   = status_transitions
    STATUS_TRANSITIONS_WITH_FINAL_REVIEW = status_transitions final: true
    FINAL_STATUS                         = final_status
    PENDING_STATUS                       = pending_status
    EXCLUDE_FROM_REPORTS_STATUS          = exclude_from_reports_status
    PENDING_FOR_REVIEW_STATUS            = pending_for_review_status

    define_state_scopes
    define_state_methods
  end

  module ClassMethods
    private

      def status
        {
          confirmed:           -3,
          unconfirmed:         -2,
          unanswered:          -1,
          awaiting:            -4,
          being_implemented:   0,
          implemented:         1,
          implemented_audited: 2,
          assumed_risk:        3,
          notify:              4,
          incomplete:          5,
          repeated:            6,
          revoked:             7,
          criteria_mismatch:   8,
          expired:             9
        }.with_indifferent_access.freeze
      end

      def status_transitions final: false
        {
          confirmed:           confirmed_transitions(final),
          unconfirmed:         unconfirmed_transitions(final),
          unanswered:          unanswered_transitions(final),
          awaiting:            awaiting_transitions(final),
          being_implemented:   being_implemented_transitions(final),
          implemented:         implemented_transitions(final),
          implemented_audited: implemented_audited_transitions(final),
          assumed_risk:        assumed_risk_transitions(final),
          notify:              notify_transitions(final),
          incomplete:          incomplete_transitions(final),
          repeated:            repeated_transitions(final),
          revoked:             revoked_transitions(final),
          criteria_mismatch:   criteria_mismatch_transitions(final),
          expired:             expired_transitions(final)
        }.with_indifferent_access.freeze
      end

      def final_status
        [STATUS[:implemented_audited], STATUS[:revoked], STATUS[:expired]] |
          (ALLOW_FINDING_ASSUMED_RISK_TO_PENDING ? [] : [STATUS[:assumed_risk]]) |
          (HIDE_FINDING_CRITERIA_MISMATCH ? [] : [STATUS[:criteria_mismatch]])
      end

      def pending_status
        [
          STATUS[:being_implemented], STATUS[:notify], STATUS[:implemented],
          STATUS[:unconfirmed], STATUS[:confirmed], STATUS[:unanswered],
          STATUS[:incomplete]
        ] |
        (ALLOW_FINDING_ASSUMED_RISK_TO_PENDING ? [STATUS[:assumed_risk]] : []) |
        (SHOW_WEAKNESS_PROGRESS ? [STATUS[:awaiting]] : [])
      end

      def define_state_scopes
        scope :revoked,     -> { where     state: STATUS[:revoked] }
        scope :not_revoked, -> { where.not state: STATUS[:revoked] }
        scope :assumed_risk,     -> { where     state: STATUS[:assumed_risk] }
        scope :not_assumed_risk, -> { where.not state: STATUS[:assumed_risk] }
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
        [:unconfirmed, :confirmed, :notify, :incomplete, :repeated, :revoked] |
          (SHOW_WEAKNESS_PROGRESS ? [] : [:awaiting])
      end

      def pending_for_review_status
        [
          STATUS[:awaiting],
          STATUS[:being_implemented],
          STATUS[:implemented],
          STATUS[:unanswered],
        ] |
        (SHOW_ASSUMED_RISK_AS_REVIEW_PENDING ? [STATUS[:assumed_risk]] : [])
      end

      def confirmed_transitions final
        [:confirmed, :unanswered, :being_implemented, :implemented, :implemented_audited, :assumed_risk, :expired] |
          (final ? [] : [:revoked]) |
          (SHOW_WEAKNESS_PROGRESS ? [:awaiting] : []) |
          (HIDE_FINDING_CRITERIA_MISMATCH ? [] : [:criteria_mismatch])
      end

      def unconfirmed_transitions final
        [:unconfirmed, :confirmed, :unanswered]
      end

      def unanswered_transitions final
        [:unanswered, :being_implemented, :implemented, :implemented_audited, :assumed_risk, :expired, :repeated] |
          (final ? [] : [:revoked]) |
          (SHOW_WEAKNESS_PROGRESS ? [:awaiting] : []) |
          (HIDE_FINDING_CRITERIA_MISMATCH ? [] : [:criteria_mismatch])
      end

      def awaiting_transitions final
        [:awaiting, :being_implemented, :implemented, :implemented_audited, :assumed_risk, :expired, :repeated] |
          (final ? [] : [:revoked]) |
          (HIDE_FINDING_CRITERIA_MISMATCH ? [] : [:criteria_mismatch])
      end

      def being_implemented_transitions final
        [:being_implemented, :implemented, :implemented_audited, :assumed_risk, :expired, :repeated] |
          (final ? [] : [:revoked]) |
          (HIDE_FINDING_CRITERIA_MISMATCH ? [] : [:criteria_mismatch])
      end

      def implemented_transitions final
        [:implemented, :awaiting, :being_implemented, :implemented_audited, :assumed_risk, :expired, :repeated] |
          (final ? [] : [:revoked]) |
          (HIDE_FINDING_CRITERIA_MISMATCH ? [] : [:criteria_mismatch])
      end

      def implemented_audited_transitions final
        [:implemented_audited]
      end

      def assumed_risk_transitions final
        [:assumed_risk] |
          (ALLOW_FINDING_ASSUMED_RISK_TO_PENDING ? [:awaiting, :being_implemented] : [])
      end

      def notify_transitions final
        [:notify, :incomplete, :confirmed, :being_implemented, :implemented, :implemented_audited, :assumed_risk, :expired] |
          (final ? [] : [:revoked]) |
          (SHOW_WEAKNESS_PROGRESS ? [:awaiting] : []) |
          (HIDE_FINDING_CRITERIA_MISMATCH ? [] : [:criteria_mismatch])
      end

      def incomplete_transitions final
        [:incomplete, :notify, :being_implemented, :implemented, :implemented_audited, :assumed_risk, :expired] |
          (final ? [] : [:revoked]) |
          (SHOW_WEAKNESS_PROGRESS ? [:awaiting] : []) |
          (HIDE_FINDING_CRITERIA_MISMATCH ? [] : [:criteria_mismatch])
      end

      def repeated_transitions final
        [:repeated]
      end

      def revoked_transitions final
        [:revoked]
      end

      def criteria_mismatch_transitions final
        [:criteria_mismatch]
      end

      def expired_transitions final
        [:expired]
      end

      def visible_pending_status
        PENDING_STATUS - [STATUS[:incomplete]]
      end

      def report_pending_status
        STATUS.except(*EXCLUDE_FROM_REPORTS_STATUS).values & PENDING_STATUS
      end
  end

  def pending?
    PENDING_STATUS.include?(self.state)
  end

  def next_status_list state = nil
    state_key    = STATUS.invert[state || state_was || self.state]
    allowed_keys = review&.has_final_review? ?
      STATUS_TRANSITIONS_WITH_FINAL_REVIEW[state_key] :
      STATUS_TRANSITIONS[state_key]

    STATUS.select { |k,| allowed_keys.include? k.to_sym }
  end

  def status_change_history
    findings_with_status_changed = versions_with_state_change

    if findings_with_status_changed.last.try(:state) != state
      u_id = self.paper_trail.originator
      self.user_who_make_it = u_id && User.find(u_id)

      findings_with_status_changed << self
    end

    findings_with_status_changed
  end

  def state_text
    state ? I18n.t("findings.state.#{STATUS.invert[state]}") : '-'
  end

  private

    def versions_with_state_change
      last_state = nil

      versions.each_with_object([]) do |version, result|
        finding = version.reify has_one: false

        if finding && finding.state != last_state
          last_state = finding.state

          if u_id = version.paper_trail_originator
            finding.user_who_make_it = User.find u_id
          end

          result << finding
        end
      end
    end
end
