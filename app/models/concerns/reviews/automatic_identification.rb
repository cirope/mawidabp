module Reviews::AutomaticIdentification
  extend ActiveSupport::Concern

  included do
    attr_reader :identification_prefix,
                :identification_number,
                :identification_suffix

    if SHOW_REVIEW_AUTOMATIC_IDENTIFICATION && Rails.env.production?
      attr_readonly :identification
    end
  end

  module ClassMethods
    def next_identification_number prefix, suffix, use_prefix: false
      pattern        = use_prefix ? "#{prefix}-%/#{suffix}" : "%/#{suffix}"
      regex          = /(\d+)\/#{suffix}\Z/i
      relation_scope = where(
        "#{quoted_table_name}.#{qcn 'identification'} LIKE ?", pattern
      ).joins(
        :business_unit_type
      ).where(
        business_unit_types: { independent_identification: use_prefix }
      )

      last_identification = relation_scope.reorder(:id).last&.identification

      last_number = String(last_identification).match(regex)&.captures&.first

      '%03d' % last_number.to_i.next
    end
  end
end
