class WorkPaper < ApplicationRecord
  include ActiveStorage::HasOneFile
  include Auditable
  include ParameterSelector
  include Comparable
  include WorkPapers::LocalFiles
  include WorkPapers::Review

  # Named scopes
  scope :list, -> { where(organization_id: Current.organization&.id) }
  scope :sorted_by_code, -> { order(code: :asc) }
  scope :with_prefix, ->(prefix) {
    where("#{quoted_table_name}.#{qcn 'code'} LIKE ?", "#{prefix}%").sorted_by_code
  }

  # Restricciones de los atributos
  attr_accessor :code_prefix,
                :from_sidekiq,
                :zip_must_be_created,
                :cover_must_be_created,
                :previous_code

  attr_readonly :organization_id

  # Callbacks
  before_save :check_for_modifications
  after_save :create_cover_and_zip
  after_destroy :destroy_file_model # TODO: delete when Rails fix gets in stable

  # Restricciones
  validates :organization_id, :name, :code, :presence => true
  validates :number_of_pages, :numericality =>
    {:only_integer => true, :less_than => 100000, :greater_than => 0},
    :allow_nil => true, :allow_blank => true
  validates :organization_id, :numericality => {:only_integer => true},
    :allow_nil => true, :allow_blank => true
  validates :name, :code, :length => {:maximum => 255}, :allow_nil => true,
    :allow_blank => true
  validates :code, :uniqueness => { :scope => :owner_id }, :on => :create,
    :allow_nil => true, :allow_blank => true
  validates :name, :code, :description, :pdf_encoding => true
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
  belongs_to :file_model, :optional => true
  belongs_to :owner, :polymorphic => true, :touch => true, :optional => true

  accepts_nested_attributes_for :file_model, :allow_destroy => true,
    reject_if: ->(attrs) { ['file', 'file_cache'].all? { |a| attrs[a].blank? } }

  def initialize(attributes = nil)
    super(attributes)

    self.organization_id = Current.organization&.id
  end

  def inspect
    number_of_pages.present? ? "#{code} - #{name} (#{pages_to_s})" : "#{code} - #{name}"
  end

  def <=>(other)
    if other.kind_of?(WorkPaper) && self.owner_id == other.owner_id && self.owner_type == other.owner_type
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

  def create_pdf_cover filename, review
    pdf = Prawn::Document.create_generic_pdf(:portrait, footer: false)

    pdf.add_review_header review.try(:organization),
                          review.try(:identification),
                          review.try(:plan_item).try(:project)

    pdf.move_down PDF_FONT_SIZE * 2

    pdf.add_title WorkPaper.model_name.human, PDF_FONT_SIZE * 2

    pdf.move_down PDF_FONT_SIZE * 4

    if owner.respond_to?(:pdf_cover_items)
      owner.pdf_cover_items.each do |label, text|
        pdf.move_down PDF_FONT_SIZE

        pdf.add_description_item label, text, 0, false
      end
    end

    unless name.blank?
      pdf.move_down PDF_FONT_SIZE

      pdf.add_description_item WorkPaper.human_attribute_name(:name),
                               name,
                               0,
                               false
    end

    unless description.blank?
      pdf.move_down PDF_FONT_SIZE

      pdf.add_description_item WorkPaper.human_attribute_name(:description),
                               description,
                               0,
                               false
    end

    unless code.blank?
      pdf.move_down PDF_FONT_SIZE

      pdf.add_description_item WorkPaper.human_attribute_name(:code),
                               code,
                               0,
                               false
    end

    unless number_of_pages.blank?
      pdf.move_down PDF_FONT_SIZE

      pdf.add_description_item WorkPaper.human_attribute_name(:number_of_pages),
                               number_of_pages.to_s,
                               0,
                               false
    end

    pdf.save_as absolute_cover_path(filename)
  end

  def pdf_cover_name filename
    I18n.t 'work_paper.cover_name', prefix: "#{sanitized_code}-",
                                    filename: File.basename(filename, File.extname(filename))
  end

  def absolute_cover_path filename
    File.join TEMP_PATH, pdf_cover_name(filename)
  end

  private

    def check_for_modifications
      self.zip_must_be_created   = file.attached? || file.changed?
      self.cover_must_be_created = changed?
      self.previous_code         = code_was if code_changed?
    end

    def create_cover_and_zip
      ZipWorkPaperJob.set(wait: 10.seconds).perform_later self, previous_code if perform_job?
    end

    def perform_job?
      file.attached? &&
        (zip_must_be_created || cover_must_be_created) &&
        !from_sidekiq
    end

    def sanitized_code
      code.sanitized_for_filename
    end

    def destroy_file_model
      file_model.try(:destroy!)
    end
end
