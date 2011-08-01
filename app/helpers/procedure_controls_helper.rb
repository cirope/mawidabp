module ProcedureControlsHelper
  def procedure_control_best_practices_select(procedure_control_id)
    select_tag "#{procedure_control_id}_best_practice", options_for_select(
      options_array_for(BestPractice.list, :name, :id, true)),
      :class => :best_practice, :autofocus => true
  end
end