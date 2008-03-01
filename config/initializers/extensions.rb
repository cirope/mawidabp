# Configuración del modelo con la configuración de la aplicación
ActiveRecord::Base.send :include, ModelConfig

Numeric.send :include, ActiveSupport::CoreExtensions::Numeric::BusinessTime
Date.send :include, ActiveSupport::CoreExtensions::Date::BusinessTime
ActionView::Base.send :include, ActionView::Helpers::DateHelper::CustomExtension

class ActiveRecord::Base
  # Devuelve siempre una versión correcta para la fecha
  def version_of(date = nil)
    if date && date.to_time <= Time.now && self.respond_to?(:versions)
      self.versions.first(
        :conditions => ['created_at <= :from', {:from => date.to_time}],
        :order => 'created_at DESC'
      ).try(:reify) || self.versions.first.try(:reify) || self
    else
      self
    end
  end

  def self.prepare_search_conditions(*conditions)
    (conditions || []).map { |c| "(#{self.sanitize_sql(c)})" }.join(' AND ')
  end

  def self.get_column_name(column)
    self::COLUMNS_FOR_SEARCH[column][:column]
  end

  def self.get_column_operator(column)
    self::COLUMNS_FOR_SEARCH[column][:operator]
  end

  def self.get_column_mask(column)
    self::COLUMNS_FOR_SEARCH[column][:mask]
  end

  def self.get_column_conversion_method(column)
    self::COLUMNS_FOR_SEARCH[column][:conversion_method]
  end

  def self.get_column_regexp(column)
    self::COLUMNS_FOR_SEARCH[column][:regexp]
  end
end

# Reescribe el comportamiento por defecto del etiquetado de los campos con
# errores de validación
ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
    # msg = instance.error_message
    error_class = 'error_field'

    if html_tag =~ /<(input|textarea|select|label)[^>]+class=/
        class_attribute = html_tag =~ /class=['"]/
        html_tag.insert(class_attribute + 7, "#{error_class} ")
    elsif html_tag =~ /<(input|textarea|select|label)/
        first_whitespace = html_tag =~ /\s/
        html_tag[first_whitespace] = " class=\"#{error_class}\" "
    end
    
    html_tag
end

# Agrega una conversión de UTF-8 a ISO a la funcion text de PDF::Writer
CONVERTER_TO_ISO = Iconv.new 'ISO-8859-15//IGNORE//TRANSLIT', 'UTF-8'
CONVERTER_TO_UTF8 = Iconv.new 'UTF-8//IGNORE//TRANSLIT', 'ISO-8859-15'

module PDF
  class Writer
    include PDF::PDFExtension
    
    alias :text_old :text

    def text(utf_text, options = {})
      text_old CONVERTER_TO_ISO.iconv(utf_text), options
    end

    alias :save_as_old :save_as

    def save_as(name)
      FileUtils.rm name if File.exist?(name)

      save_as_old name
    end
  end
end

# Extensión de la clase String
class String
  def to_iso
    result = String.new

    # Por línea para evitar un desborde en la función iconv cuando el string es
    # muy grande
    self.each_line { |substr| result << CONVERTER_TO_ISO.iconv(substr) }
    
    result
  end

  def to_utf8
    result = String.new

    # Por línea para evitar un desborde en la función iconv cuando el string es
    # muy grande
    self.each_line { |substr| result << CONVERTER_TO_UTF8.iconv(substr) }

    result
  end

  # Convierte un cadena en un entero que representa el tiempo en segundos
  # Por ejemplo:
  # 
  # * '1:15'.fetch_time               # => 4500
  # * '1h15m'.fetch_time              # => 4500
  # * '1 hora 15 minutos'.fetch_time  # => 4500
  def fetch_time
    hours_match = self.match /(:*)(\d+\.?\d*)\s*([h]*)([ms]*)/
    minutes_match = self.match /((:*)\:(\d+\.?\d*))|((\d+\.?\d*)\s*m)/
    seconds_match = self.match /:.*:\D*(\d+\.?\d*)|(\d+\.?\d*)\s*s/
    hours = hours_match && hours_match[1].blank? && hours_match[4].blank? ?
      hours_match[2].to_f : 0
    minutes = minutes_match && minutes_match[2].blank? ?
      (minutes_match[5] || minutes_match[3]).to_f : 0
    seconds = seconds_match ? (seconds_match[2] || seconds_match[1]).to_f : 0

    ((hours + minutes / 60.0 + seconds / 3600.0) * 3600).round
  end
end