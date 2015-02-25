module BenefitsHelper
  def benefit_kinds
    ['tangible', 'intangible'].map do |k|
      [t("benefits.kinds.#{k}"), k]
    end
  end
end
