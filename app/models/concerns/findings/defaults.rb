module Findings::Defaults
  extend ActiveSupport::Concern

  included do
    after_initialize :set_defaults, if: :new_record?
  end

  private

    def set_defaults
      if control_objective_item&.control && !HIDE_WEAKNESS_EFFECT
        self.effect ||= control_objective_item.control.effects
      end

      self.state            ||= Finding::STATUS[:incomplete]
      self.final            ||= false
      self.finding_prefix   ||= false
      self.origination_date ||= default_origination_date
    end

    def default_origination_date
      prefix = Current.organization.prefix

      if ORGANIZATIONS_WITH_CONTROL_OBJECTIVE_COUNTS.exclude? prefix
        Time.zone.today
      end
    end
end
