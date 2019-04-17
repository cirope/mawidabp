module BestPracticesHelper
  def nested_process_controls
    @best_practice.process_controls.build if @best_practice.process_controls.blank?

    @best_practice.process_controls
  end

  def best_practice_shared_icon best_practice
    if best_practice.shared
      title = [
        BestPractice.human_attribute_name('shared'),
        "(#{best_practice.organization.name})"
      ].join ' '

      content_tag :span, nil, class: 'glyphicon glyphicon-eye-open', title: title
    end
  end

  def process_control_path process_control
    if process_control.persisted?
      edit_best_practice_process_control_path @best_practice, process_control
    else
      new_best_practice_process_control_path @best_practice
    end
  end

  def should_fetch_control_objectives_for? process_control
    is_valid = process_control.errors.empty?
    control_objectives_are_unchanged = process_control.control_objectives.all? do |co|
      co.persisted? && co.errors.empty? && !co.changed?
    end

    is_valid && control_objectives_are_unchanged
  end

  def link_to_download_support control_objective, options = {}
    if control_objective.support? && control_objective.support.present?
      best_practice   = control_objective.best_practice
      default_options = {
        class: 'btn btn-default btn-sm',
        title: control_objective.identifier.titleize,
        data:  { ignore_unsaved_data: true }
      }.merge(options)

      link_to download_best_practice_control_objective_path(best_practice, control_objective), default_options do
        content_tag(:span, nil, class: 'icon glyphicon glyphicon-download-alt')
      end
    end
  end
end
