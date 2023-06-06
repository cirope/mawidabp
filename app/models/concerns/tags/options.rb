module Tags::Options
  extend ActiveSupport::Concern

  included do
    serialize :options, JSON unless POSTGRESQL_ADAPTER
  end

  def is_boolean? option
    option_type(option) == :boolean
  end

  def required_min
    option_value 'required_min_count'
  end

  def required_min_label
    option_label 'required_min_count'
  end

  def required_max
    option_value 'required_max_count'
  end

  def required_max_label
    option_label 'required_max_count'
  end

  def required_from
    option_value 'required_from'
  end

  def required_from_label
    option_label 'required_from'
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
    if value = Hash(options)[option]
      case option_type(option)
      when :date_picker
        human ? I18n.l(Date.parse(value)) : value
      when :boolean
        value = value == '1'

        human ? I18n.t("label.#{value ? 'yes' : 'no'}") : value
      when :integer
        value.to_i
      else
        value
      end
    end
  end

  private

    def option_label option
      TAG_OPTIONS[kind].invert[option]
    end
end
