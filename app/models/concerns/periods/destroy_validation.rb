module Periods::DestroyValidation
  extend ActiveSupport::Concern

  included do
    before_destroy :check_if_can_be_destroyed
  end

  private

    def can_be_destroyed?
      [:reviews, :plan, :workflows].each do |method|
        collection = send(method)

        unless collection.blank?
          errors.add :base, add_error_for(method, collection)
        end
      end

      errors.blank?
    end

    def add_error_for method, collection
      I18n.t "periods.errors.#{method}", count: Array(collection).size
    end

    def check_if_can_be_destroyed
      throw :abort unless can_be_destroyed?
    end
end
