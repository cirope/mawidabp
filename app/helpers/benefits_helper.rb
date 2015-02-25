module BenefitsHelper
  def benefit_kinds
    ['tangible', 'intangible'].map do |k|
      [t("benefits.kinds.#{k}"), k]
    end
  end

  def allow_benefit_kind_edition?
    @benefit.achievements.empty?
  end
end
