module Weaknesses::SigenFields
  extend ActiveSupport::Concern

  included do
    after_save :update_sigen_fields_in_repeated_of
  end

  private

    def update_sigen_fields_in_repeated_of
      unless update_sigen_fields_in_repeated_of?
        Rails.logger.warn('no se pudo actualizar los campos sigen')
      end
    end

    def update_sigen_fields_in_repeated_of?
      %w(bic).include?(Current.conclusion_pdf_format) &&
        repeated_of&.update(year: year, nsisio: nsisio, nobs: nobs)
    end
end
