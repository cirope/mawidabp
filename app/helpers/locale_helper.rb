module LocaleHelper
  def language_options
    AVAILABLE_LOCALES.map do |lang|
      [I18n.t("lang.#{lang}"), lang.to_s]
    end.sort { |a, b| a[0] <=> b[0] }
  end
end
