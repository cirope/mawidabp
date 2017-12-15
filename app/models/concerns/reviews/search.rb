module Reviews::Search
  extend ActiveSupport::Concern

  included do
    COLUMNS_FOR_SEARCH = {
      period:         period_options,
      identification: identification_options,
      business_unit:  business_unit_options,
      project:        project_options,
      audit_team:     audit_team_options
    }.with_indifferent_access
  end

  module ClassMethods
    private

      def period_options
        string_column_options_for "#{Period.quoted_table_name}.#{Period.qcn 'name'}"
      end

      def identification_options
        string_column_options_for "#{quoted_table_name}.#{qcn 'identification'}"
      end

      def business_unit_options
        string_column_options_for "#{BusinessUnit.quoted_table_name}.#{BusinessUnit.qcn 'name'}"
      end

      def project_options
        string_column_options_for "#{::PlanItem.quoted_table_name}.#{::PlanItem.qcn 'project'}"
      end

      def audit_team_options
        string_column_options_for "#{User.quoted_table_name}.#{User.qcn 'last_name'}"
      end

      def string_column_options_for column
        {
          column:            "LOWER(#{column})",
          operator:          'LIKE',
          mask:              "%%%s%%",
          conversion_method: :to_s,
          regexp:            /.*/
        }
      end
  end
end
