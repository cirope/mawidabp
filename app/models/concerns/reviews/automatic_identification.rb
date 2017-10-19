module Reviews::AutomaticIdentification
  extend ActiveSupport::Concern

  included do
    attr_reader :identification_prefix,
                :identification_number,
                :identification_suffix
  end

  module ClassMethods
    def next_identification_number prefix, suffix
      regex = /#{prefix}-(\d+)\/#{suffix}/i
      last_identification =
        where("#{quoted_table_name}.#{qcn 'identification'} LIKE ?", "#{prefix}-%/#{suffix}").
        order(:identification).
        last&.
        identification

      last_number = String(last_identification).match(regex)&.captures&.first

      '%03d' % (last_number&.to_i&.next || 1)
    end
  end
end
