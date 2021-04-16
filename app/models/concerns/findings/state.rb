module Findings::State
  extend ActiveSupport::Concern

  included do
    STATUS                               = status
    STATUS_TRANSITIONS                   = status_transitions
    STATUS_TRANSITIONS_WITH_FINAL_REVIEW = status_transitions final: true
    FINAL_STATUS                         = final_status
    PENDING_STATUS                       = pending_status
    REPEATED_STATUS                      = repeated_status
    EXCLUDE_FROM_REPORTS_STATUS          = exclude_from_reports_status
    PENDING_FOR_REVIEW_STATUS            = pending_for_review_status

    define_state_scopes
    define_state_methods
  end

  def has_final_status?
    FINAL_STATUS.include? state
  end

  module ClassMethods
    def with_pending_status
      where state: visible_pending_status
    end

    def with_repeated_status
      where state: REPEATED_STATUS
    end

    def with_pending_status_for_report
      where state: report_pending_status
    end

    private

      def status
        {
          failure:             -5,
          awaiting:            -4,
          confirmed:           -3,
          unconfirmed:         -2,
          unanswered:          -1,
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
          expired:             expired_transitions(final),
          failure:             failure_transitions(final)
        }.with_indifferent_access.freeze
      end

      def final_status
        [STATUS[:implemented_audited], STATUS[:revoked], STATUS[:expired]] |
          (ALLOW_FINDING_ASSUMED_RISK_TO_PENDING || HIDE_FINDING_IMPLEMENTED_AND_ASSUMED_RISK ? [] : [STATUS[:assumed_risk]]) |
          (HIDE_FINDING_CRITERIA_MISMATCH ? [] : [STATUS[:criteria_mismatch]])
      end

      def pending_status
        [
          STATUS[:being_implemented], STATUS[:notify], STATUS[:unconfirmed],
          STATUS[:confirmed], STATUS[:unanswered], STATUS[:incomplete]
        ] |
        (ALLOW_FINDING_ASSUMED_RISK_TO_PENDING && !HIDE_FINDING_IMPLEMENTED_AND_ASSUMED_RISK ? [STATUS[:assumed_risk]] : []) |
        (HIDE_FINDING_IMPLEMENTED_AND_ASSUMED_RISK ? [] : [STATUS[:implemented]]) |
        (SHOW_WEAKNESS_PROGRESS ? [STATUS[:awaiting]] : [])
      end

      def repeated_status
        STATUS[:repeated]
      end

      def define_state_scopes
        scope :revoked,     -> { where     state: STATUS[:revoked] }
        scope :not_revoked, -> { where.not state: STATUS[:revoked] }

        scope :assumed_risk,     -> { where     state: STATUS[:assumed_risk] }
        scope :not_assumed_risk, -> { where.not state: STATUS[:assumed_risk] }

        scope :implemented_audited, -> { where state: STATUS[:implemented_audited] }
      end

      def define_state_methods
        STATUS.each do |type, value|
          define_method("#{type}?")     { state     == value }
          define_method("was_#{type}?") { state_was == value }
        end
      end

      def exclude_from_reports_status
        [:unconfirmed, :confirmed, :notify, :incomplete, :repeated, :revoked] |
          (HIDE_FINDING_IMPLEMENTED_AND_ASSUMED_RISK ? [:implemented, :assumed_risk] : [])
      end

      def pending_for_review_status
        [
          STATUS[:being_implemented],
          STATUS[:unanswered],
        ] |
        (SHOW_ASSUMED_RISK_AS_REVIEW_PENDING && !HIDE_FINDING_IMPLEMENTED_AND_ASSUMED_RISK ? [STATUS[:assumed_risk]] : []) |
        (HIDE_FINDING_IMPLEMENTED_AND_ASSUMED_RISK ? [] : [STATUS[:implemented]])
      end

      def confirmed_transitions final
        [:confirmed, :unanswered, :being_implemented, :implemented_audited, :expired] |
          (final ? [] : [:revoked]) |
          (HIDE_FINDING_CRITERIA_MISMATCH ? [] : [:criteria_mismatch]) |
          (HIDE_FINDING_IMPLEMENTED_AND_ASSUMED_RISK ? [] : [:implemented, :assumed_risk])
      end

      def unconfirmed_transitions final
        [:unconfirmed, :confirmed, :unanswered]
      end

      def unanswered_transitions final
        [:unanswered, :being_implemented, :implemented_audited, :expired, :repeated] |
          (final ? [] : [:revoked]) |
          (HIDE_FINDING_CRITERIA_MISMATCH ? [] : [:criteria_mismatch]) |
          (HIDE_FINDING_IMPLEMENTED_AND_ASSUMED_RISK ? [] : [:implemented, :assumed_risk])
      end

      def awaiting_transitions final
        [:awaiting, :being_implemented, :implemented, :implemented_audited, :assumed_risk, :expired, :repeated] |
          (final ? [] : [:revoked]) |
          (HIDE_FINDING_CRITERIA_MISMATCH ? [] : [:criteria_mismatch])
      end

      def being_implemented_transitions final
        [:being_implemented, :implemented_audited, :expired, :repeated] |
          (final ? [] : [:revoked]) |
          (SHOW_WEAKNESS_PROGRESS ? [:awaiting] : []) |
          (HIDE_FINDING_CRITERIA_MISMATCH ? [] : [:criteria_mismatch]) |
          (HIDE_FINDING_IMPLEMENTED_AND_ASSUMED_RISK ? [] : [:implemented, :assumed_risk])
      end

      def implemented_transitions final
        [:being_implemented, :implemented_audited, :expired, :repeated] |
          (final ? [] : [:revoked]) |
          (SHOW_WEAKNESS_PROGRESS ? [:awaiting] : []) |
          (HIDE_FINDING_CRITERIA_MISMATCH ? [] : [:criteria_mismatch]) |
          (HIDE_FINDING_IMPLEMENTED_AND_ASSUMED_RISK ? [] : [:implemented, :assumed_risk])
      end

      def implemented_audited_transitions final
        [:implemented_audited] |
          (
            if final
              []
            else
              [:being_implemented, :revoked] |
                (HIDE_FINDING_IMPLEMENTED_AND_ASSUMED_RISK ? [] : [:implemented])
            end
          )
      end

      def assumed_risk_transitions final
        [:assumed_risk] |
          (ALLOW_FINDING_ASSUMED_RISK_TO_PENDING ? [:being_implemented] : [])
      end

      def notify_transitions final
        [:notify, :incomplete, :confirmed, :being_implemented, :implemented_audited, :expired] |
          (final ? [] : [:revoked]) |
          (HIDE_FINDING_CRITERIA_MISMATCH ? [] : [:criteria_mismatch]) |
          (HIDE_FINDING_IMPLEMENTED_AND_ASSUMED_RISK ? [] : [:implemented, :assumed_risk])
      end

      def incomplete_transitions final
        [:incomplete, :notify, :being_implemented, :implemented_audited, :expired] |
          (final ? [] : [:revoked]) |
          (SHOW_WEAKNESS_PROGRESS ? [:awaiting] : []) |
          (SHOW_WEAKNESS_PROGRESS ? [:failure] : []) |
          (HIDE_FINDING_CRITERIA_MISMATCH ? [] : [:criteria_mismatch]) |
          (HIDE_FINDING_IMPLEMENTED_AND_ASSUMED_RISK ? [] : [:implemented, :assumed_risk])
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
        [:expired] |
          (
            if final
              []
            else
              [:being_implemented] |
                (HIDE_FINDING_IMPLEMENTED_AND_ASSUMED_RISK ? [] : [:implemented])
            end
          )
      end

      def failure_transitions final
        [:failure]
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

  def full_state_text
    if latest
      "#{state_text} (#{latest.state_text} - #{latest.review.identification})"
    else
      state_text
    end
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
