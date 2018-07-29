module BusinessUnits::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> {
      joins(:business_unit_type).where(business_unit_types: {
        organization_id: Current.organization.id
      }).references(:business_unit_types)
    }
  end

  module ClassMethods
    def by_names *names
      conditions, parameters = *name_conditions(names)

      where conditions.join(' OR '), parameters
    end

    private

      def name_conditions names
        conditions = []
        parameters = {}

        names.each_with_index do |name, i|
          conditions << "LOWER(#{quoted_table_name}.#{qcn 'name'}) LIKE :bu_#{i}"
          parameters[:"bu_#{i}"] = "%#{name.mb_chars.downcase}%"
        end

        [conditions, parameters]
      end
  end
end
