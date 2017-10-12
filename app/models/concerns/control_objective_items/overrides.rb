module ControlObjectiveItems::Overrides
  extend ActiveSupport::Concern

  def to_s
    if exclude_from_score
      post_fix = " (#{I18n.t('control_objective_item.not_applicable')})"
    end

    "#{control_objective_text.chomp}#{post_fix}"
  end

  def as_json options = nil
    default_options = {
      only:    [:id],
      methods: [:label, :informal]
    }

    super default_options.merge(options || {})
  end

  def <=> other
    if other.kind_of? ControlObjectiveItem
      if id == other.id
        0
      elsif review_id == other.review_id
        (order_number || -1) <=> (other.order_number || -1)
      else
        -1
      end
    else
      -1
    end
  end

  def == other
    if other.kind_of? ControlObjectiveItem
      if new_record? && other.new_record?
        object_id == other.object_id
      else
        id == other.id
      end
    else
      false
    end
  end
end
