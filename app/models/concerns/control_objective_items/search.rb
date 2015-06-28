module ControlObjectiveItems::Search
  extend ActiveSupport::Concern

  included do
    COLUMNS_FOR_SEARCH = HashWithIndifferentAccess.new(
      review:                 review_options,
      process_control:        process_control_options,
      control_objective_text: control_objective_text_options
    )
  end

  module ClassMethods
    private

    def review_options
      {
        column:            "LOWER(#{Review.quoted_table_name}.#{Review.qcn('identification')})",
        operator:          'LIKE',
        mask:              '%%%s%%',
        conversion_method: :to_s,
        regexp:            /.*/
      }
    end

    def process_control_options
      {
        column:            "LOWER(#{ProcessControl.quoted_table_name}.#{ProcessControl.qcn('name')})",
        operator:          'LIKE',
        mask:              "%%%s%%",
        conversion_method: :to_s,
        regexp:            /.*/
      }
    end

    def control_objective_text_options
      {
        column:            "LOWER(#{quoted_table_name}.#{qcn('control_objective_text')})",
        operator:          'LIKE',
        mask:              "%%%s%%",
        conversion_method: :to_s,
        regexp:            /.*/
      }
    end
  end
end
