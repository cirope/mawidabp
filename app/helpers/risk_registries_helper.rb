module RiskRegistriesHelper
  def nested_risk_categories
    @risk_registry.risk_categories.build if @risk_registry.risk_categories.blank?

    @risk_registry.risk_categories
  end

  def risk_category_path risk_category
    if risk_category.persisted?
      edit_risk_registry_risk_category_path @risk_registry, risk_category
    else
      new_risk_registry_risk_category_path @risk_registry
    end
  end

  def should_fetch_risks_for? risk_category
    is_valid            = risk_category.errors.empty?
    risks_are_unchanged = risk_category.risks.all? do |risk|
      risk.persisted? && risk.errors.empty? && !risk.changed?
    end

    is_valid && risks_are_unchanged
  end
end
