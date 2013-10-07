module ProcedureControlsHelper
  def procedure_control_best_practices_select(procedure_control_id)
    select_tag "#{procedure_control_id}_best_practice", options_for_select(
      options_array_for(BestPractice.list, :name, :id, true)),
      :class => :best_practice, :autofocus => true
  end

  def approach_field(form)
    form.select :aproach,
      ProcedureControlItem::APPROACH_TYPES.map { |k,v| [t("approach_types.#{k}"), v] }
  end

  def frequency_field(form)
    form.select :frequency,
      ProcedureControlItem::FREQUENCY_TYPES.map { |k,v| [t("frequency_types.#{k}"), v] }
  end
end
