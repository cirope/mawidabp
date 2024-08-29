module Risks::I18nRiskHelpers
  extend ActiveSupport::Concern

  def likelihood_to_s
    "#{Risk.t_likelihood Risk::LIKELIHOODS.invert[likelihood]} (#{likelihood})"
  end

  def impact_to_s
    "#{Risk.t_impact Risk::IMPACTS.invert[impact]} (#{impact})"
  end

  module ClassMethods
    def likelihood_label_for name
      "#{t_likelihood name} (#{Risk::LIKELIHOODS[name]})"
    end

    def impact_label_for name
      "#{t_impact name} (#{Risk::IMPACTS[name]})"
    end

    def t_likelihood name
      I18n.t "risks.likelihoods.#{name}"
    end

    def t_impact name
      I18n.t "risks.impacts.#{name}"
    end
  end
end
