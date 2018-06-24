module Reviews::WorkPapersZip
  extend ActiveSupport::Concern

  def zip_all_work_papers organization = nil
    filename = absolute_work_papers_zip_path

    FileUtils.rm filename if File.exists?(filename)
    FileUtils.makedirs File.dirname(filename)

    Zip::File.open(filename, Zip::File::CREATE) do |zipfile|
      add_control_objective_work_papers_to zipfile
      add_finding_work_papers_to zipfile
      add_survey_to zipfile
    end

    FileUtils.chmod 0640, filename
  end

  def absolute_work_papers_zip_path
    File.join PRIVATE_PATH, work_papers_zip_path
  end

  def relative_work_papers_zip_path
    "/private/#{work_papers_zip_path}"
  end

  def work_papers_zip_path
    work_papers_label = WorkPaper.model_name.human count: 0
    filename_prefix   = work_papers_label.downcase.sanitized_for_filename
    path              =
      ('%08d' % (Current.organization_id || 0)).scan(/\d{4}/) +
      [Review.table_name] +
      ('%08d' % id).scan(/\d{4}/) +
      ["#{filename_prefix}-#{sanitized_identification}.zip"]

    File.join *path
  end

  def add_work_paper_to_zip wp, dir, zipfile, prefix = nil
    has_file   = wp.file_model&.file? && File.exist?(wp.file_model.file.path)
    file_model = wp.file_model

    if has_file
      add_file_to_zip file_model.file.path, file_model.identifier, dir, zipfile
    else
      identification = "#{prefix}#{sanitized_identification}"

      wp.create_pdf_cover identification, self

      cover_path = wp.absolute_cover_path identification
      cover_name = wp.pdf_cover_name identification

      add_file_to_zip cover_path, cover_name, dir, zipfile
    end
  end

  def add_file_to_zip path, filename, dir, zipfile
    zip_filename = File.join dir, filename.sanitized_for_filename

    zipfile.add(zip_filename, path) { true } if File.exist?(path)
  end

  private

    def add_work_papers_from enumerable, zipfile, i18n_dir_key, prefix = nil
      dir = I18n.t(i18n_dir_key).sanitized_for_filename

      enumerable.each do |item|
        item.work_papers.each do |item_wp|
          add_work_paper_to_zip item_wp, dir, zipfile, prefix
        end
      end
    end

    def add_control_objective_work_papers_to zipfile
      i18n_dir_key = 'review.control_objectives_work_papers'

      add_work_papers_from control_objective_items, zipfile, i18n_dir_key
    end

    def add_finding_work_papers_to zipfile
      weaknesses, oportunities, findings = [], [], []

      if has_final_review?
        weaknesses   = final_weaknesses.not_revoked
        oportunities = final_oportunities.not_revoked
        findings     = self.weaknesses.not_revoked + self.oportunities.not_revoked
      else
        weaknesses   = self.weaknesses.not_revoked
        oportunities = self.oportunities.not_revoked
        findings     = []
      end

      add_work_papers_from weaknesses,   zipfile, 'review.weaknesses_work_papers',   'E_'
      add_work_papers_from oportunities, zipfile, 'review.oportunities_work_papers', 'E_'
      add_work_papers_from findings,     zipfile, 'review.follow_up_work_papers',    'S_'
    end

    def add_survey_to zipfile
      dir = Review.human_attribute_name 'survey'

      if file_model&.file?
        add_file_to_zip file_model.file.path, file_model.identifier, dir, zipfile
      end

      if survey.present?
        survey_pdf organization

        add_file_to_zip absolute_survey_pdf_path, survey_pdf_name, dir, zipfile
      end
    end
end
