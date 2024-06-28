module RisksHelper
  def risk_likelihoods
    Risk::LIKELIHOODS.map do |name, value|
      [Risk.likelihood_label_for(name), value]
    end
  end

  def risk_impacts
    Risk::IMPACTS.map do |name, value|
      [Risk.impact_label_for(name), value]
    end
  end

  def risk_control_objectives control_objectives
    if control_objectives.present?
      content_tag :ul, class: 'ps-2' do
        control_objectives.each do |control_objective|
          concat content_tag(:li, control_objective.name)
        end
      end
    end
  end
end
