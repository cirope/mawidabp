module TagsHelper
  def tag_kinds
    {
      finding: Finding.model_name.human(count: 0)
    }
  end

  def styles
    styles = %w(default primary success info warning danger)

    styles.map { |k| [t("tags.styles.#{k}"), k] }
  end
end
