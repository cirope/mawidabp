# Configuración del modelo con la configuración de la aplicación
ActiveRecord::Base.send :include, ModelConfig

Numeric.send :include, ActiveSupport::CoreExtensions::Numeric::BusinessTime
Date.send :include, ActiveSupport::CoreExtensions::Date::BusinessTime
ActionView::Base.send :include, ActionView::Helpers::DateHelper::CustomExtension

Paperclip.interpolates(:organization_id) do
  ('%08d' % (GlobalModelConfig.current_organization_id || 0)).scan(/\d{4}/).join(File::SEPARATOR)
end

Paperclip.interpolates(:id) do |attachment, style_name|
  ('%08d' % attachment.instance.id).scan(/\d{4}/).join(File::SEPARATOR)
end

# Parche feo hasta que actualizen paperclip
if defined? ActionDispatch::Http::UploadedFile
  ActionDispatch::Http::UploadedFile.send(:include, Paperclip::Upfile)
end

class ActiveRecord::Base
  # Devuelve siempre una versión correcta para la fecha
  def version_of(date = nil)
    if date && date.to_time <= Time.now && self.respond_to?(:versions)
      # Tiene que ser posterior ya que se guarda el estado _anterior_ en las
      # versiones
      self.versions.order('created_at ASC').where(
        'created_at > :from', :from => date.to_time
      ).first.try(:reify) || self
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

  def self.allow_search_operator?(operator, column)
    operators = self.get_column_operator(column)

    if operators.kind_of?(Array)
      operators.include?(operator)
    else
      operators == operator
    end
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
require 'iconv'

CONVERTER_TO_ISO = Iconv.new 'ISO-8859-15//IGNORE//TRANSLIT', 'UTF-8'
CONVERTER_TO_UTF8 = Iconv.new 'UTF-8//IGNORE//TRANSLIT', 'ISO-8859-15'

module PDF
  class Writer
    include PDF::PDFExtension
    
    alias :text_old :text

    def text(utf_text, options = {})
      text_old utf_text.to_iso, options
    end

    alias :save_as_old :save_as

    def save_as(name)
      FileUtils.rm name if File.exist?(name)

      save_as_old name
    end
  end
end

# Extensión de la clase Object
class Object
  def to_translated_string
    if self.respond_to?(:strftime)
      I18n.l(self, :format => :long)
    else
      self.to_s
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
    hours_match = self.match /(:*)(\d+\.?\d*)\s*([h]*)([ms]*)/i
    minutes_match = self.match /((:*)\:(\d+\.?\d*))|((\d+\.?\d*)\s*m)/i
    seconds_match = self.match /:.*:\D*(\d+\.?\d*)|(\d+\.?\d*)\s*s/i
    hours = hours_match && hours_match[1].blank? && hours_match[4].blank? ?
      hours_match[2].to_f : 0
    minutes = minutes_match && minutes_match[2].blank? ?
      (minutes_match[5] || minutes_match[3]).to_f : 0
    seconds = seconds_match ? (seconds_match[2] || seconds_match[1]).to_f : 0

    ((hours + minutes / 60.0 + seconds / 3600.0) * 3600).round
  end

  def split_if_no_space_in(max_characters = 50, split_character = "\n")
    self.to_s.scan(/.{1,#{max_characters}}/).map do |chunk|
      chunk.index(/\s/) || chunk.length < max_characters ?
        chunk : "#{chunk}#{split_character}"
    end.join
  end

  def sanitized_for_filename
    @_sanitized_for_filename ||= self.gsub /[^A-Za-z0-9\.\-]+/, '_'
  end
end

class Version
  def changes_until(other)
    changes = []
    old_attributes = self.reify.try(:attributes) || {}
    new_attributes =
      (other.try(:reify) || self.item.try(:reload)).try(:attributes) || {}
    item_class = self.try(:class) || self.item.try(:class)

    old_attributes.each do |attribute, old_value|
      new_value = new_attributes.delete attribute

      if old_value != new_value && !(old_value.blank? && new_value.blank?)
        changes << HashWithIndifferentAccess.new({
          :attribute => item_class.human_attribute_name(attribute),
          :old_value => old_value.to_translated_string.split_if_no_space_in(50),
          :new_value => new_value.to_translated_string.split_if_no_space_in(50)
        })
      end
    end

    new_attributes.each do |attribute, new_value|
      changes << HashWithIndifferentAccess.new({
        :attribute => item_class.human_attribute_name(attribute),
        :old_value => '-',
        :new_value => new_value
      })
    end

    changes
  end

  def changes_from_next
    self.changes_until(self.next)
  end
end