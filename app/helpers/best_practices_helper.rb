module BestPracticesHelper
  def nested_process_controls
    @best_practice.process_controls.build if @best_practice.process_controls.blank?

    @best_practice.process_controls
  end

  def best_practice_shared_icon best_practice
    icon = content_tag :span, nil, class: 'glyphicon glyphicon-eye-open', title: t('activerecord.attributes.best_practice.shared')

    best_practice.shared ? icon : ''
  end

  def process_control_path process_control
    if process_control.persisted?
      edit_best_practice_process_control_path @best_practice, process_control
    else
      new_best_practice_process_control_path @best_practice
    end
  end
end
