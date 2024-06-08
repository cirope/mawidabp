module WeaknessesHelper
  def show_weakness_previous_follow_up_dates(weakness)
    list = String.new.html_safe
    out = String.new.html_safe

    if weakness.being_implemented? || weakness.awaiting?
      dates = weakness.all_follow_up_dates
    end

    if dates.present?
      dates.each { |d| list << content_tag(:li, l(d, :format => :long)) }

      out << link_to(t('weakness.previous_follow_up_dates'), '#', :onclick =>
        "$('#previous_follow_up_dates').slideToggle();return false;")

      out << content_tag(:div, content_tag(:ol, list),
        :id => 'previous_follow_up_dates', :style => 'display: none; margin-bottom: 1em;')

      content_tag(:div, out, :style => 'margin-bottom: 1em;')
    end
  end

  def next_weakness_work_paper_code(weakness, follow_up = false)
    review = weakness.control_objective_item.try(:review)
    code_prefix = follow_up ?
      t('code_prefixes.work_papers_in_weaknesses_follow_up') :
      weakness.work_paper_prefix

    code_from_review = review ?
      review.last_weakness_work_paper_code(prefix: code_prefix) :
      "#{code_prefix} 0".strip

    work_paper_codes = weakness.work_papers.reject(
      &:marked_for_destruction?).map(
      &:code).select { |c| c =~ /#{code_prefix}\s\d+/ }

    last_code = work_paper_codes.map do |code|
      code.match(/\d+\Z/)[0].to_i if code =~ /\d+\Z/
    end.compact.sort.last.to_i

    next_number = [code_from_review.match(/\d+\Z/)[0].to_i, last_code].max

    "#{code_prefix} #{next_number}"
  end

  def benefit_exists?
    Benefit.list.exists?
  end

  def weakness_achievements_for kind
    Benefit.list.where(kind: kind).order(created_at: :asc).map do |benefit|
      achievement = @weakness.achievements.detect { |a| a.benefit_id == benefit.id }

      achievement || @weakness.achievements.new(benefit_id: benefit.id)
    end
  end

  def weakness_business_units
    @weakness.control_objective_item.business_units
  end

  def weakness_compliance_options
    COMPLIANCE_OPTIONS.map do |option, options|
      [t("label.#{option}"), option, options]
    end
  end

  def weakness_compliance_maybe_sanction_options
    COMPLIANCE_MAYBE_SANCTION_OPTIONS.map do |k, v|
      [t("label.#{k}"), v]
    end
  end

  def weakness_operational_risk_options
    WEAKNESS_OPERATIONAL_RISK.map { |option, options| [option, option, options] }
  end

  def weakness_impact_options
    WEAKNESS_IMPACT.map { |option, options| [option, option, options] }
  end

  def weakness_internal_control_components_options
    WEAKNESS_INTERNAL_CONTROL_COMPONENTS.map { |option| [option, option] }
  end

  def show_weakness_templates?
    @weakness.new_record? &&
      @weakness.weakness_template_id.blank? &&
      WeaknessTemplate.list.any?
  end

  def weakness_templates_for weakness
    control_objective  = weakness.control_objective_item&.control_objective

    control_objective &&
      WeaknessTemplate.list.by_control_objective(control_objective)
  end

  def weakness_risk_data_options
    if SHOW_CONDENSED_PRIORITIES
      { toggle_priority: Finding.risks[:medium], toggle_compliance: Finding.risks[:low] }
    elsif USE_SCOPE_CYCLE
      { copy_priority: true }
    else
      {}
    end
  end

  def weakness_impact_risks
    if USE_SCOPE_CYCLE
      Finding.impact_risks.map do |key, value|
        [t("impact_risk_types.#{key}"), value]
      end
    else
      Finding.impact_risks_bic.map do |key, value|
        [t("bic_impact_risk_types.#{key}"), value]
      end
    end
  end

  def weakness_probabilities
    if USE_SCOPE_CYCLE
      Finding.probabilities.map do |key, value|
        [t("probability_types.#{key}"), value]
      end
    else
      Finding.frequencies.map do |key, value|
        [t("frequencies_types.#{key}"), value]
      end
    end
  end

  def weakness_state_regulations
    Finding.state_regulations.map do |key, value|
      [t("state_regulations_types.#{key}"), value]
    end
  end


  def weakness_degree_compliance
    Finding.degree_compliance.map do |key, value|
      [t("degree_compliance_types.#{key}"), value]
    end
  end

  def weakness_observation_origination_tests
    Finding.observation_origination_tests.map do |key, value|
      [t("observation_originated_tests_types.#{key}"), value]
    end
  end

  def weakness_sample_deviation
    Finding.sample_deviation.map do |key, value|
      [t("sample_deviation_types.#{key}"), value]
    end
  end

  def weakness_external_repeated
    Finding.external_repeated.map do |key, value|
      [t("external_repeated_types.#{key}"), value]
    end
  end

  def suggested_type_risks
    Finding::SUGGESTED_IMPACT_RISK_TYPES.map do |key, value|
      [t("suggested_type_risks.#{key}"), value]
    end
  end

  def suggested_type_probabilities
    Finding::SUGGESTED_PROBABILITIES_TYPES.map do |key, value|
      [t("suggested_type_probabilities.#{key}"), value]
    end
  end

  def skip_reiteration_copy
    Current.organization.skip_reiteration_copy?
  end
end
