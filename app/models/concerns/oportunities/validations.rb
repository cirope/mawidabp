module Oportunities::Validations
  extend ActiveSupport::Concern

  included do
    validates_each :review_code do |record, attr, value|
      revoked_prefix = I18n.t 'code_prefixes.revoked'
      regex          = /\A#{revoked_prefix}?#{record.prefix}\d+\Z/

      record.errors.add attr, :invalid unless value =~ regex
    end
  end
end
