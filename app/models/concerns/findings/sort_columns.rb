module Findings::SortColumns
  extend ActiveSupport::Concern

  module ClassMethods
    def columns_for_sort
      {
        risk_asc:             risk_asc_options,
        risk_desc:            risk_desc_options,
        state:                state_options,
        review:               review_options,
        updated_at_asc:       updated_at_asc_options,
        updated_at_desc:      updated_at_desc_options,
        follow_up_date_asc:   follow_up_date_asc_options,
        follow_up_date_desc:  follow_up_date_desc_options
      }.with_indifferent_access
    end

    private

      def risk_asc_options
        {
          name: "#{human_attribute_name(:risk)} - #{human_attribute_name(:priority)} (#{I18n.t('label.ascendant')})",
          field: ["#{table_name}.risk ASC", "#{table_name}.priority ASC", "#{table_name}.state ASC"]
        }
      end

      def risk_desc_options
        {
          name: "#{human_attribute_name(:risk)} - #{human_attribute_name(:priority)} (#{I18n.t('label.descendant')})",
          field: ["#{table_name}.risk DESC", "#{table_name}.priority DESC", "#{table_name}.state ASC"]
        }
      end

      def state_options
        { name: human_attribute_name(:state), field: "#{table_name}.state ASC" }
      end

      def review_options
        {
          name: Review.model_name.human,
          field: "#{Review.table_name}.identification ASC"
        }
      end

      def updated_at_asc_options
        {
          name: "#{human_attribute_name(:updated_at)} (#{I18n.t('label.ascendant')})",
          field: "#{table_name}.updated_at ASC"
        }
      end

      def updated_at_desc_options
        {
          name: "#{human_attribute_name(:updated_at)} (#{I18n.t('label.descendant')})",
          field: "#{table_name}.updated_at DESC"
        }
      end

      def follow_up_date_asc_options
        {
          name: "#{human_attribute_name(:follow_up_date)}  (#{I18n.t('label.ascendant')})",
          field: "#{table_name}.follow_up_date ASC"
        }
      end

      def follow_up_date_desc_options
        {
          name: "#{human_attribute_name(:follow_up_date)}  (#{I18n.t('label.descendant')})",
          field: "#{table_name}.follow_up_date DESC"
        }
      end
  end
end
