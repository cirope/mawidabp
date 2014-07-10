module Periods::DestroyValidation
  extend ActiveSupport::Concern

  included do
    before_destroy :can_be_destroyed?
  end

  private

    def can_be_destroyed?
      [:reviews, :plans, :workflows, :procedure_controls].each do |method|
        collection = send(method)

        unless collection.blank?
          errors.add :base, add_error_for(method, collection)
        end
      end

      errors.blank?
    end

    def add_error_for method, collection
      I18n.t "periods.errors.#{method}", count: collection.size
    end
end
