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
end
