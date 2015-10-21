module ConclusionReviews::Scopes
  extend ActiveSupport::Concern

  module ClassMethods
    def by_business_unit_names(final, *business_unit_names)
      conditions, parameters = business_unit_conditions business_unit_names

      ids_by_weaknesses = includes(business_unit_includes(final)).where(
        conditions.join(' OR '), parameters
      ).references(:business_units).pluck('id')

      ids_by_review = includes(plan_item: :business_unit).where(
        conditions.join(' OR '), parameters
      ).references(:business_units).pluck('id')

      where(id: ids_by_weaknesses | ids_by_review)
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
    
      def business_unit_includes final
        business_units = { business_unit_findings: :business_unit }
        weaknesses_include = final ?
          { final_weaknesses: business_units } :
          { weaknesses: business_units }

        {
          review: {
            control_objective_items: weaknesses_include
          }
        }
      end
  end
end
