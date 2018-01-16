module Parameters::Qualification
  extend ActiveSupport::Concern

  included do
    unless defined? ::QUALIFICATION_TYPES
      ::QUALIFICATION_TYPES = qualification_types
    end
  end


  module ClassMethods
    def qualifications
      QUALIFICATION_TYPES
    end

    def qualifications_values
      QUALIFICATION_TYPES.values
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
