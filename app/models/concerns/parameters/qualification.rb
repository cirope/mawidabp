module Parameters::Qualification
  extend ActiveSupport::Concern

  included do
    unless defined? ::QUALIFICATION_TYPES
      ::QUALIFICATION_TYPES = qualification_types
    end
  end

  DEFAULT_QUALIFICATION_TYPES = {
    not_rated: 0,
    very_low: 1,
    low: 2,
    moderately_low: 3,
    medium_low: 4,
    medium: 5,
    moderately_high: 6,
    medium_high: 7,
    high: 8,
    very_high: 9,
    excellent: 10
  }

  def qualifications
    self.class.qualifications date:      created_at,
                              translate: true
  end

  module ClassMethods
    def qualifications show_value: !SHOW_SHORT_QUALIFICATIONS,
                       date:       nil,
                       translate:  false

      if REVIEW_MANUAL_SCORE && Current.organization
        Current.organization.
          control_objective_item_scores(date: date).with_indifferent_access
      elsif translate
        QUALIFICATION_TYPES.map do |k, v|
          text = [
            I18n.t("qualification_types.#{k}"),
            ("(#{v})" if show_value)
          ].compact.join(' ')

          [text, v]
        end
      else
        QUALIFICATION_TYPES
      end
    end

    def qualifications_values date: nil
      qualifications(date: date).values
    end

    private

      def qualification_types
        if SHOW_SHORT_QUALIFICATIONS
          {
            ok: 10,
            observed: 1,
            not_apply: 0
          }
        else
          {
            not_rated: 0,
            very_low: 1,
            low: 2,
            moderately_low: 3,
            medium_low: 4,
            medium: 5,
            moderately_high: 6,
            medium_high: 7,
            high: 8,
            very_high: 9,
            excellent: 10
          }
        end
      end
  end
end
