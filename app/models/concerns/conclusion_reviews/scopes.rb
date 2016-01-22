module ConclusionReviews::Scopes
  extend ActiveSupport::Concern

  module ClassMethods
    def by_business_unit_names(*business_unit_names)
      conditions, parameters = business_unit_conditions business_unit_names

      ids_by_control_objectives = includes(business_unit_includes).where(
        conditions.join(' OR '), parameters
      ).references(:business_units).pluck('id')

      ids_by_review = includes(plan_item: :business_unit).where(
        conditions.join(' OR '), parameters
      ).references(:business_units).pluck('id')

      where(id: ids_by_control_objectives | ids_by_review)
    end

    private

      def business_unit_conditions business_unit_names
        conditions = []
        parameters = {}

        business_unit_names.each_with_index do |business_unit_name, i|
          conditions << "LOWER(#{BusinessUnit.quoted_table_name}.#{BusinessUnit.qcn 'name'}) LIKE :bu_#{i}"
          parameters[:"bu_#{i}"] = "%#{business_unit_name.mb_chars.downcase}%"
        end

        [conditions, parameters]
      end

      def business_unit_includes
        {
          review: {
            control_objective_items: { business_unit_scores: :business_unit }
          }
        }
      end
  end
end
