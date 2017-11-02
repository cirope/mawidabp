module Reviews::ControlObjectiveItems
  extend ActiveSupport::Concern

  included do
    attr_reader   :control_objective_ids, :process_control_ids
    attr_accessor :control_objective_data, :process_control_data

    has_many :control_objective_items, dependent: :destroy, after_add: :assign_review

    accepts_nested_attributes_for :control_objective_items, allow_destroy: true
  end

  def process_control_ids= process_control_ids
    Array(process_control_ids).uniq.each do |process_control_id|
      if ProcessControl.exists? process_control_id
        process_control = ProcessControl.find process_control_id

        process_control.control_objectives.each do |control_objective|
          add_control_objective_item_from control_objective
        end
      end
    end
  end

  def control_objective_ids= control_objective_ids
    ids = if ALLOW_REVIEW_CONTROL_OBJECTIVE_DUPLICATION
            Array(control_objective_ids)
          else
            Array(control_objective_ids).uniq
          end

    ids.each do |control_objective_id|
      if ControlObjective.exists? control_objective_id
        control_objective = ControlObjective.find control_objective_id

        add_control_objective_item_from control_objective
      end
    end
  end

  def grouped_control_objective_items options = {}
    grouped_control_objective_items = group_control_objective_items options

    grouped_control_objective_items.to_a.sort do |gcoi1, gcoi2|
      pc1 = gcoi1.last.map(&:order_number).compact.min || -1
      pc2 = gcoi2.last.map(&:order_number).compact.min || -1

      pc1 <=> pc2
    end
  end

  private

    def assign_review related_object
      related_object.review = self
    end

    def add_control_objective_item_from control_objective
      control_objective_ids = control_objective_items.map &:control_objective_id
      is_not_included       = control_objective_ids.exclude? control_objective.id
      duplication_allowed   = ALLOW_REVIEW_CONTROL_OBJECTIVE_DUPLICATION

      if !control_objective.obsolete && (is_not_included || duplication_allowed)
        coi_attributes = control_objective_item_attributes_for control_objective

        control_objective_items.build coi_attributes
      end
    end

    def control_objective_item_attributes_for control_objective
      {
        control_objective_id:   control_objective.id,
        control_objective_text: control_objective.name,
        relevance:              control_objective.relevance,
        control_attributes:     {
          control:          control_objective.control.control,
          effects:          control_objective.control.effects,
          design_tests:     control_objective.control.design_tests,
          compliance_tests: control_objective.control.compliance_tests,
          sustantive_tests: control_objective.control.sustantive_tests
        }
      }
    end

    def group_control_objective_items options
      grouped_items = {}
      items         = if options[:hide_excluded_from_score]
                        control_objective_items.reject &:exclude_from_score
                      else
                        control_objective_items
                      end

      items.each do |item|
        grouped_items[item.process_control] ||= []

        if grouped_items[item.process_control].exclude?(item)
          grouped_items[item.process_control] << item
        end
      end

      grouped_items
    end
end
