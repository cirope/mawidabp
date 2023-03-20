class ZipWorkPaperJob < ApplicationJob
  queue_as :default

  attr_accessor :previous_code

  def perform work_paper, previous_code
    Current.user       = User.third
    self.previous_code = previous_code

    work_paper.from_sidekiq = true

    create_zip work_paper
  end

  private

    def create_zip work_paper
      unzip_if_necesary work_paper

      old_path = ActiveStorage::Blob.service.path_for work_paper.file.key

      work_paper.reload

      prev_code         = sanitized_previous_code if previous_code
      original_filename = work_paper.file.blob.filename.to_s
      code              = sanitized_code work_paper
      short_code        = sanitized_code(work_paper).sub(/(\w+_)\d(\d{2})$/, '\1\2')
      filename          = File.basename original_filename, File.extname(original_filename)
      filename          = filename.sanitized_for_filename
                                  .sub(/^(#{Regexp.quote(code)})?\-?(zip-)*/i, '')
                                  .sub(/^(#{Regexp.quote(short_code)})?\-?(zip-)*/i, '')
      filename          = filename.sub "#{prev_code}-", '' if prev_code
      tmp_user_folder   = "tmp/zips_for_work_papers/#{work_paper.id}"

      FileUtils.mkdir_p tmp_user_folder unless Dir.exist? tmp_user_folder

      zip_filename = File.join tmp_user_folder, "#{code}-#{filename}.zip"
      pdf_filename = absolute_cover_path work_paper

      create_pdf_cover work_paper

      path_download_file_attached = "#{File.join tmp_user_folder, filename}#{File.extname original_filename}"

      File.open path_download_file_attached, 'wb' do |file_tmp|
        work_paper.file.download { |chunk| file_tmp.write chunk }
      end

      Zip::File.open zip_filename, Zip::File::CREATE do |zf|
        zf.add File.basename(pdf_filename), pdf_filename
        zf.add filename_with_prefix(work_paper), path_download_file_attached
      end

      work_paper.file.attach io: File.open(zip_filename),
                             content_type: 'application/zip',
                             filename: File.basename(zip_filename)

      FileUtils.rm_rf old_path if File.exist? old_path

      FileUtils.rm_rf File.dirname(old_path) if Dir.empty? File.dirname(old_path)

      FileUtils.rm_rf File.dirname(File.dirname(old_path)) if Dir.empty? File.dirname(File.dirname(old_path))

      FileUtils.rm_rf tmp_user_folder
    end

  def unzip_if_necesary work_paper
    file_name = work_paper.file.blob.filename.to_s || ''

    if File.extname(file_name) == '.zip' && start_with_code?(file_name, work_paper)
      zip_path = ActiveStorage::Blob.service.path_for work_paper.file.key

      filename_to_attach = ''

      Zip::File.foreach zip_path do |entry|
        if entry.file?
          filename = File.join File.dirname(zip_path), entry.name

          if previous_code
            filename = filename.sub sanitized_previous_code, sanitized_code(work_paper)
          end

          if filename != zip_path &&
             !File.exist?(filename) &&
             File.basename(filename) != pdf_cover_name(work_paper) &&
             File.basename(filename) != pdf_cover_name(work_paper, nil, true)
            entry.extract filename

            filename_to_attach = filename
          end
        end
      end

      work_paper.file.attach io: File.open(filename_to_attach),
                             filename: File.basename(filename_to_attach)

      FileUtils.rm_rf filename_to_attach if File.exist? filename_to_attach

      FileUtils.rm_rf File.dirname(filename_to_attach) if Dir.empty? File.dirname(filename_to_attach)

      FileUtils.rm_rf File.dirname(File.dirname(filename_to_attach)) if Dir.empty? File.dirname(File.dirname(filename_to_attach))
    end
  end

  def pdf_cover_name work_paper, filename = nil, short = false
    code       = sanitized_code work_paper
    short_code = sanitized_code(work_paper).sub(/(\w+_)\d(\d{2})$/, '\1\2')
    prev_code  = previous_code.sanitized_for_filename if previous_code

    if work_paper.file.attached?
      filename ||= work_paper.file.blob.filename.to_s.sanitized_for_filename

      filename = filename.sanitized_for_filename
                         .sub(/^(#{Regexp.quote(code)})?\-?(zip-)*/i, '')
                         .sub(/^(#{Regexp.quote(short_code)})?\-?(zip-)*/i, '')
      filename = filename.sub "#{prev_code}-", '' if prev_code
    end

    I18n.t 'work_paper.cover_name', prefix: "#{short ? short_code : code}-",
                                    filename: File.basename(filename, File.extname(filename))
  end

  def sanitized_code work_paper
    work_paper.code.sanitized_for_filename
  end

  def sanitized_previous_code
    previous_code.sanitized_for_filename
  end

  def start_with_code? file_name, work_paper
    code       = sanitized_code work_paper
    short_code = sanitized_code(work_paper).sub(/(\w+_)\d(\d{2})$/, '\1\2')
    result     = file_name.start_with?(code, short_code) &&
                 !file_name.start_with?("#{code}-zip", "#{short_code}-zip")

    if previous_code
      prev_code       = sanitized_previous_code
      prev_short_code = prev_code.sub(/(\w+_)\d(\d{2})$/, '\1\2')

      result ||= file_name.start_with?(prev_code, prev_short_code) &&
                 !file_name.start_with?("#{prev_code}-zip", "#{prev_short_code}-zip")
    end

    result
  end

  def absolute_cover_path work_paper
    tmp_user_folder = "tmp/zips_for_work_papers/#{work_paper.id}"

    File.join tmp_user_folder, pdf_cover_name(work_paper)
  end

  def create_pdf_cover work_paper
    pdf    = Prawn::Document.create_generic_pdf(:portrait, footer: false)
    review = work_paper.owner.review

    pdf.add_review_header review.try(:organization),
                          review.try(:identification),
                          review.try(:plan_item).try(:project)

    pdf.move_down PDF_FONT_SIZE * 2

    pdf.add_title WorkPaper.model_name.human, PDF_FONT_SIZE * 2

    pdf.move_down PDF_FONT_SIZE * 4

    if work_paper.owner.respond_to? :pdf_cover_items
      work_paper.owner.pdf_cover_items.each do |label, text|
        pdf.move_down PDF_FONT_SIZE

        pdf.add_description_item label, text, 0, false
      end
    end

    unless work_paper.name.blank?
      pdf.move_down PDF_FONT_SIZE

      pdf.add_description_item WorkPaper.human_attribute_name(:name),
                               work_paper.name,
                               0,
                               false
    end

    unless work_paper.description.blank?
      pdf.move_down PDF_FONT_SIZE

      pdf.add_description_item WorkPaper.human_attribute_name(:description),
                               work_paper.description,
                               0,
                               false
    end

    unless work_paper.code.blank?
      pdf.move_down PDF_FONT_SIZE

      pdf.add_description_item WorkPaper.human_attribute_name(:code),
                               work_paper.code,
                               0,
                               false
    end

    unless work_paper.number_of_pages.blank?
      pdf.move_down PDF_FONT_SIZE

      pdf.add_description_item WorkPaper.human_attribute_name(:number_of_pages),
                               work_paper.number_of_pages.to_s,
                               0,
                               false
    end

    pdf.save_as absolute_cover_path(work_paper)
  end

  def filename_with_prefix work_paper
    filename    = work_paper.file.blob.filename.to_s.sub(/^(zip-)*/i, '')
    filename    = filename.sanitized_for_filename
    code_suffix = File.extname(filename) == '.zip' ? '-zip' : ''
    code        = sanitized_code work_paper
    short_code  = sanitized_code(work_paper).sub(/(\w+_)\d(\d{2})$/, '\1\2')

    filename.starts_with?(code, short_code) ? filename : "#{code}#{code_suffix}-#{filename}"
  end
end
