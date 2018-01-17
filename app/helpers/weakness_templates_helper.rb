module WeaknessTemplatesHelper
  def show_weakness_template_allow_duplication? weakness_template
    title_errors = weakness_template.errors.details[:title]

    weakness_template.allow_duplication? ||
      title_errors.any? { |msg| msg[:error] == :taken }
  end
end
