class FileModel < ActiveRecord::Base
  include Auditable
  include ParameterSelector

  mount_uploader :file, FileUploader, :mount_on => :file_file_name

  # Atributos no persistentes
  attr_accessor :delete_file

  # Callbacks
  before_save :destroy_file?, :update_file_attributes

  # Restricciones
  validates :file_file_name, :file_content_type, :length => { :maximum => 255 },
    :allow_nil => true, :allow_blank => true
  validates_each :file do |record, attr, value|
    if record.identifier && File.extname(record.identifier).blank?
      record.errors.add attr, :without_extension
    end
  end

  def delete_file?
    self.delete_file == '1' || self.delete_file == true
  end

  def destroy_file?
    self.remove_file! if self.delete_file?
  end

  alias_method :_changed_original?, :changed?

  def changed?
    self.file.cached?.present? || self.delete_file? || _changed_original?
  end

  def identifier
    self.file.identifier || self.file_identifier
  end

  private

  def update_file_attributes
    if file.present? && file_file_name_changed?
      self.file_content_type = file.file.content_type
      self.file_file_size = file.file.size
      self.file_updated_at = Time.now
    end
  end
end
