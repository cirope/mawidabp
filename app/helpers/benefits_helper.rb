module BenefitsHelper
  def benefit_kinds
    [
      'benefit_tangible',
      'benefit_intangible',
      'damage_tangible',
      'damage_intangible'
    ].map { |k| [t("benefits.kinds.#{k}"), k] }
  end

  def allow_benefit_kind_edition?
    @benefit.achievements.empty?
  end
end
