class Parameter < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new {GlobalModelConfig.current_organization_id},
    :important => Proc.new {|parameter| parameter.name.starts_with?('security')}
  }

  serialize :value

  # Named scopes
  # Deprecated
  scope :all_parameters, lambda { |name|
    {
      :conditions => {
        :organization_id => GlobalModelConfig.current_organization_id,
        :name => name.to_s
      }
    }
  }

  # Callbacks
  after_save :add_to_cache
  after_destroy :remove_from_cache

  # Restricciones de los atributos
  attr_readonly :name
  
  # Restricciones
  validates_format_of :name, :with => /\A\w+\z/,
    :allow_nil => true, :allow_blank => true
  validates_presence_of :name, :value, :organization_id
  validates_length_of :name, :maximum => 100, :allow_nil => true,
    :allow_blank => true
  validates_uniqueness_of :name, :case_sensitive => false,
    :scope => :organization_id

  # Relaciones
  belongs_to :organization

  def to_s
    I18n.t "parameter.#{self.name}"
  end

  def add_to_cache
    Parameter.write_in_cache self
  end

  def remove_from_cache
    cache_key = "#{self.organization_id}_#{self.name}"
    cached_versions = Rails.cache.read(cache_key).try(:dup) || []

    cached_versions.delete_if { |p| p.id == self.id }

    Rails.cache.write(cache_key, cached_versions)
  end

  def self.find_parameter(organization_id, name, version = nil)
    parameter = Parameter.find_in_cache(organization_id, name, version)

    unless parameter
      parameter = self.first(
        :conditions => {:name => name.to_s, :organization_id => organization_id}
      ).try(:version_of, version)

      Parameter.write_in_cache(parameter)
    end

    parameter.try(:value) || DEFAULT_PARAMETERS[name.to_sym]
  end

  def self.find_in_cache(organization_id, name, version = nil)
    results = Rails.cache.read("#{organization_id}_#{name}") || []
    parameter = nil

    if version.respond_to?(:to_time)
      parameter = results.detect { |p| version.to_time >= p.updated_at }
    end

    parameter
  end

  def self.write_in_cache(parameter)
    if parameter
      cache_key = "#{parameter.organization_id}_#{parameter.name}"
      cached_versions = Rails.cache.read(cache_key).try(:dup) || []

      cached_versions.delete_if do |p|
        p.modification_date == parameter.modification_date
      end

      cached_versions << parameter
      
      cached_versions.sort! do |p1, p2|
        p2.modification_date <=> p1.modification_date
      end

      Rails.cache.write(cache_key, cached_versions)
    end
  end

  def modification_date
    self.updated_at || self.created_at || Time.now
  end
end