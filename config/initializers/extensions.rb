# Importar Builder si no fue importado previamente
require 'active_support/builder' unless defined?(Builder)

Numeric.send :include, ActiveSupport::CoreExtensions::Numeric::BusinessTime
Date.send :include, ActiveSupport::CoreExtensions::Date::BusinessTime
ActionView::Base.send :include, ActionView::Helpers::DateHelper::CustomExtension

class ActiveRecord::Base
  def version_of(date = nil)
    if date && date.to_time <= Time.now && respond_to?(:versions)
      condition = "#{PaperTrail::Version.quoted_table_name}.#{PaperTrail::Version.qcn 'created_at'} > ?"

      versions.where(condition, date.to_time).first.try(:reify) || self
    else
      self
    end
  end

  def self.qcn(name)
    connection.quote_table_name(name)
  end

  def self.prepare_search_conditions(*conditions)
    (conditions.reject(&:blank?) || []).map { |c| "(#{sanitize(c)})" }.join(' AND ')
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

  private

    def self.sanitize condition
      return nil if condition.blank?

      case condition
      when Array; sanitize_sql_array condition
      when Hash;  sanitize_hash condition
      else        condition
      end
    end

    def self.sanitize_hash attrs
      table = ActiveRecord::TableMetadata.new(self, arel_table)
      attrs = table.resolve_column_aliases attrs
      attrs = expand_hash_conditions_for_aggregates attrs

      ActiveRecord::PredicateBuilder.new(table).build_from_hash(attrs.stringify_keys).map do |b|
        connection.visitor.compile b
      end.join ' AND '
    end
end

module Prawn
  class Document
    include Prawn::Mawida::Extension

    alias :save_as :render_file
  end
end

# Extensión de la clase Object
class Object
  def to_translated_string
    if self.respond_to?(:strftime)
      I18n.l(self, format: :long)
    else
      self.to_s
    end
  end
end

# Extensión de la clase String
class String
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
    gsub /[^A-Za-z0-9\.\-]+/, '_'
  end
end
