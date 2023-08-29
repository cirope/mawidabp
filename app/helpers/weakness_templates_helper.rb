module WeaknessTemplatesHelper
  def show_weakness_template_allow_duplication? weakness_template
    _errors = weakness_template.errors.details

    weakness_template.allow_duplication? || title_and_reference_allow_duplication?(_errors)
  end

  private

    def title_and_reference_allow_duplication? errors
      %w(title reference).any? { |v| errors[v.to_sym].any? { |msg| msg[:error] == :taken }}
    end
end
