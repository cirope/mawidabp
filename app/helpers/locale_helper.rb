module LocaleHelper
  def language_options
    I18n.available_locales.map do |lang|
      [I18n.t("lang.#{lang}"), lang.to_s]
    end.sort { |a, b| a[0] <=> b[0] }
  end
end
