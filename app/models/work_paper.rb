class WorkPaper < ActiveRecord::Base
  include ParameterSelector
  include Comparable

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  # Named scopes
  scope :list, -> { where(organization_id: Organization.current_id) }
  scope :sorted_by_code, -> { order('code ASC') }
  scope :with_prefix, ->(prefix) {
    where('code LIKE :code', :code => "#{prefix}%").sorted_by_code
  }

  # Restricciones de los atributos
  attr_accessor :code_prefix
  attr_readonly :organization_id

  # Callbacks
  before_save :check_for_modifications
  after_save :create_cover_and_zip
  after_destroy :destroy_file_model # TODO: delete when Rails fix gets in stable

  # Restricciones
  validates :organization_id, :name, :code, :number_of_pages, :presence => true
  validates :number_of_pages, :numericality =>
    {:only_integer => true, :less_than => 100000, :greater_than => 0},
    :allow_nil => true, :allow_blank => true
  validates :organization_id, :numericality => {:only_integer => true},
    :allow_nil => true, :allow_blank => true
  validates :name, :code, :length => {:maximum => 255}, :allow_nil => true,
    :allow_blank => true
  validates :code, :uniqueness => { :scope => :owner_id }, :on => :create,
    :allow_nil => true, :allow_blank => true
  validates_each :code, :on => :create do |record, attr, value|
    if record.check_code_prefix && !record.marked_for_destruction?
      raise 'No code_prefix is set!' unless record.code_prefix

      regex = /^(#{Regexp.escape(record.code_prefix)})\s\d+$/

      record.errors.add attr, :invalid unless value =~ regex

      # TODO: Eliminar, duplicado para validar los objetos en memoria
      codes = record.owner.work_papers.reject(
        &:marked_for_destruction?).map(&:code)

      if codes.select { |c| c.strip == value.strip }.size > 1
        record.errors.add attr, :taken
      end
    end
  end

  # Relaciones
  belongs_to :organization
  belongs_to :file_model
  belongs_to :owner, :polymorphic => true

  accepts_nested_attributes_for :file_model, :allow_destroy => true,
    :reject_if => lambda { |attributes| attributes['file'].blank? }

  def initialize(attributes = nil, options = {})
    super(attributes, options)

    self.organization_id = Organization.current_id
  end

  def inspect
    "#{self.code} - #{self.name} (#{self.pages_to_s})"
  end

  def <=>(other)
    if self.owner_id == other.owner_id && self.owner_type == other.owner_type
      self.code <=> other.code
    else
      -1
    end
  end

  def ==(other)
    other.kind_of?(WorkPaper) && other.id &&
      (self.id == other.id || (self <=> other) == 0)
  end

  def check_code_prefix
    unless @__ccp_first_access
      @check_code_prefix = true
      @__ccp_first_access = true
    end

    @check_code_prefix
  end

  def check_code_prefix=(check_code_prefix)
    @__ccp_first_access = true

    @check_code_prefix = check_code_prefix
  end

  def pages_to_s
    I18n.t('work_paper.number_of_pages', :count => self.number_of_pages)
  end

  def check_for_modifications
    @zip_must_be_created = self.file_model.try(:file) ||
      self.file_model.try(:changed?)
    @cover_must_be_created = self.changed?

    true
  end

  def create_cover_and_zip
    self.file_model.try(:file).tap do |file|
      self.create_pdf_cover if @cover_must_be_created && file
      self.create_zip if @zip_must_be_created || (@cover_must_be_created && file)
    end

    true
  end

  def create_pdf_cover(filename = nil, review = nil)
    review ||= self.owner.kind_of?(ControlObjectiveItem) ? self.owner.review :
      (self.owner.kind_of?(Finding) ?
        self.owner.try(:control_objective_item).try(:review) : nil)
    pdf = Prawn::Document.create_generic_pdf(:portrait, false)

    pdf.add_review_header review.try(:organization),
      review.try(:identification), review.try(:plan_item).try(:project)

    pdf.move_down PDF_FONT_SIZE * 2

    pdf.add_title WorkPaper.model_name.human, PDF_FONT_SIZE * 2

    pdf.move_down PDF_FONT_SIZE * 4

    unless self.name.blank?
      pdf.move_down PDF_FONT_SIZE

      pdf.add_description_item WorkPaper.human_attribute_name(:name),
        self.name, 0, false
    end

    unless self.description.blank?
      pdf.move_down PDF_FONT_SIZE

      pdf.add_description_item WorkPaper.human_attribute_name(:description),
        self.description, 0, false
    end

    unless self.code.blank?
      pdf.move_down PDF_FONT_SIZE

      pdf.add_description_item WorkPaper.human_attribute_name(:code),
        self.code, 0, false
    end

    unless self.number_of_pages.blank?
      pdf.move_down PDF_FONT_SIZE

      pdf.add_description_item WorkPaper.human_attribute_name(
        :number_of_pages), self.number_of_pages.to_s, 0, false
    end

    pdf.save_as self.absolute_cover_path(filename)
  end

  def pdf_cover_name(filename = nil)
    if self.file_model.try(:file)
      filename ||= self.file_model.identifier.sanitized_for_filename
      filename = filename.sanitized_for_filename.sub(
        /^(#{Regexp.quote(self.sanitized_code)})?\-?(zip-)*/i, '')
    end

    I18n.t 'work_paper.cover_name', :prefix => "#{self.sanitized_code}-",
      :filename => File.basename(filename, File.extname(filename))
  end

  def absolute_cover_path(filename = nil)
    if self.file_model.try(:file)
      File.join File.dirname(self.file_model.file.path), self.pdf_cover_name
    else
      "#{TEMP_PATH}#{self.pdf_cover_name(filename || self.object_id.abs)}"
    end
  end

  def filename_with_prefix
    filename = self.file_model.identifier.sub /^(zip-)*/i, ''
    filename = filename.sanitized_for_filename
    code_suffix = File.extname(filename) == '.zip' ? '-zip' : ''

    filename.starts_with?(self.sanitized_code) ?
      filename : "#{self.sanitized_code}#{code_suffix}-#{filename}"
  end

  def create_zip
    self.unzip_if_necesary

    original_filename = self.file_model.file.path
    directory = File.dirname original_filename
    filename = File.basename original_filename, File.extname(original_filename)
    filename = filename.sanitized_for_filename.sub(
      /^(#{Regexp.quote(self.sanitized_code)})?\-?(zip-)*/i, '')
    zip_filename = File.join directory, "#{self.sanitized_code}-#{filename}.zip"
    pdf_filename = self.absolute_cover_path

    self.create_pdf_cover

    if File.file?(original_filename) && File.file?(pdf_filename)
      Zip::File.open(zip_filename, Zip::File::CREATE) do |zipfile|
        zipfile.add(self.filename_with_prefix, original_filename) { true }
        zipfile.add(File.basename(pdf_filename), pdf_filename) { true }
      end

      FileUtils.rm pdf_filename if File.exists?(pdf_filename)
      FileUtils.rm original_filename if File.exists?(original_filename)


      self.file_model.file_content_type = 'application/zip'
      self.file_model.file_file_size  = File.size(zip_filename)

      if self.file_model.save!
        self.file_model.update_column :file_file_name, File.basename(zip_filename)
      end
    end

    FileUtils.chmod 0640, zip_filename if File.exist?(zip_filename)
  end

  def unzip_if_necesary
    file_name = self.file_model.try(:identifier) || ''

    if File.extname(file_name) == '.zip' &&
        file_name.start_with?(self.sanitized_code) &&
        !file_name.start_with?("#{self.sanitized_code}-zip")
      zip_path = self.file_model.file.path
      base_dir = File.dirname self.file_model.file.path

      Zip::File.foreach(zip_path) do |entry|
        if entry.file?
          filename = File.join base_dir, entry.name
          ext = File.extname(filename)[1..-1]

          if filename != zip_path && !File.exist?(filename)
            entry.extract(filename)
          end

          if File.basename(filename) != self.pdf_cover_name
            self.file_model.update_column :file_file_name, File.basename(filename)
            self.file_model.file_content_type = Mime::Type.lookup_by_extension ext
            self.file_model.file_file_size = File.size(filename)
            self.file_model.save!
          end
        end
      end

      # Pregunta para evitar eliminar el archivo si es un zip con el mismo
      # nombre
      unless File.basename(zip_path) == self.file_model.identifier
        FileUtils.rm zip_path
      end
    end
  end

  def sanitized_code
    self.code.sanitized_for_filename
  end

  private
  
  def destroy_file_model
    file_model.try(:destroy!)
  end
end
