module Weaknesses::SigenFields
  extend ActiveSupport::Concern

  included do
    after_save :update_sigen_fields_in_repeated_of
  end

  private

    def update_sigen_fields_in_repeated_of
      if %w(bic).include?(Current.conclusion_pdf_format) && repeated_of
        unless repeated_of.update(year: year, nsisio: nsisio, nobs: nobs)
          Rails.logger.warn I18n.t('weakness.errors.cannot_update_sigen_fields_in_repeated_of', 
                                   id: repeated_of_id,
                                   messages: repeated_of.errors.full_messages)
          repeated_of.reload
        end
      end
    end
end
