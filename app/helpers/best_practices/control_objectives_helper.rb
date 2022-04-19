module BestPractices::ControlObjectivesHelper
  def link_to_download_support_file control_objective_form
    control_objective = control_objective_form.object

    if control_objective.support? && control_objective.support.cached?.blank?
      options = {
        class: 'btn btn-outline-secondary mb-3',
        title: control_objective.support.identifier.titleize,
        data: { ignore_unsaved_data: true },
        id: "control_objective_support_#{control_objective.object_id}"
      }

      link_to control_objective.support.url, options do
        icon 'fas', 'download'
      end
    end
  end

  def link_to_remove_support_file form
    control_objective = form.object
    out               = ''

    if form.object.support?
      out << form.hidden_field(
        :remove_support,
        class: 'destroy',
        value: 0,
        id: "remove_support_hidden_#{control_objective.object_id}"
      )
      out << link_to(
        icon('fas', 'times-circle'), '#',
        title: t('label.delete'),
        data: {
          'dynamic-target' => "#control_objective_support_#{control_objective.object_id}",
          'dynamic-form-event' => 'hideItembutton',
          'show-tooltip' => true
        }
      )
    end

    raw out
  end
end
