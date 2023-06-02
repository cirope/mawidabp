module Tags::Options
  extend ActiveSupport::Concern

  included do
    serialize :options, JSON unless POSTGRESQL_ADAPTER
  end

  def option_type option
    if option.end_with?('_from') || option.end_with?('_to')
      :date_picker
    elsif option.end_with? '_count'
      :integer
    else
      :boolean
    end
  end

  def option_value option, human: false
    data = options.to_h[option]

    case option_type(option)
    when :date_picker
      if data.present?
        human ? I18n.l(Date.parse(data)) : data
      end
    when :boolean
      value = data == '1'

      human ? I18n.t("label.#{value}") : value
    else
      data
    end
  end

  def is_boolean? option
    option_type(option) == :boolean
  end
end
