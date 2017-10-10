module ConclusionReviews::BundleZip
  extend ActiveSupport::Concern

  def create_bundle_zip organization, index_items
    cover_paths  = []
    cover_count  = 1

    bundle_index_pdf organization, index_items
    cover_paths << absolute_bundle_index_pdf_path

    cover_count, cover_paths =
      *get_index_covers_for(organization, index_items, cover_paths, cover_count)

    cover_count, cover_paths, cois_dir, findings_dir =
      *create_global_covers_for(organization, cover_paths, cover_count)

    cover_paths = zip_bundle_files cover_paths, {
      cois_dir:     cois_dir,
      findings_dir: findings_dir
    }

    remove_covers cover_paths
  end

  def absolute_bundle_zip_path
    Prawn::Document.absolute_path bundle_zip_name, ConclusionReview.table_name, id
  end

  def relative_bundle_zip_path
    Prawn::Document.relative_path bundle_zip_name, ConclusionReview.table_name, id
  end

  def bundle_zip_name
    I18n.t 'conclusion_review.bundle.zip_name',
      identification: review.sanitized_identification
  end

  private

    def zip_bundle_files cover_paths, dirs
      cover_paths  = cover_paths.dup
      zip_path     = absolute_bundle_zip_path
      zip_filename = File.join(*zip_path)

      FileUtils.rm zip_filename if File.exist? zip_filename

      Zip::File.open zip_filename, Zip::File::CREATE do |zipfile|
        cover_paths.each do |cover|
          if File.exist? cover
            zipfile.add(File.basename(cover), cover) { true }
          end
        end

        cover_paths = bundle_control_objective_items_on zipfile, cover_paths, dirs[:cois_dir]
        cover_paths = bundle_findings_on zipfile, cover_paths, dirs[:findings_dir]
      end

      FileUtils.chmod 0640, zip_filename

      cover_paths
    end

    def bundle_control_objective_items_on zipfile, cover_paths, dir
      cover_paths = cover_paths.dup

      if control_objective_items.any?
        zipfile.mkdir dir

        control_objective_items.each do |coi|
          filename = File.join dir, coi.pdf_name

          coi.to_pdf organization
          zipfile.add filename, coi.absolute_pdf_path { true }

          cover_paths << coi.absolute_pdf_path
        end
      end

      cover_paths
    end

    def bundle_findings_on zipfile, cover_paths, dir
      cover_paths = cover_paths.dup

      if findings.any?
        zipfile.mkdir dir

        findings.each do |finding|
          filename = File.join dir, finding.pdf_name

          finding.to_pdf organization
          zipfile.add filename, finding.absolute_pdf_path { true }

          cover_paths << finding.absolute_pdf_path
        end
      end

      cover_paths
    end

    def get_index_covers_for organization, index_items, cover_paths, cover_count
      cover_paths = cover_paths.dup

      String(index_items).each_line do |line|
        if line.present?
          name     = "#{'%02d' % cover_count}_#{line.strip.downcase}.pdf"
          pdf_name = name.sanitized_for_filename

          create_cover_pdf organization, line.strip, pdf_name

          cover_paths << absolute_cover_pdf_path(pdf_name)
          cover_count += 1
        end
      end

      [cover_count, cover_paths]
    end

    def create_global_covers_for organization, cover_paths, cover_count
      cover_paths = cover_paths.dup

      create_workflow_pdf organization

      cover_paths << absolute_workflow_pdf_path

      cois_dir = I18n.t('conclusion_review.bundle.control_objectives_dir',
                        prefix: '%02d' % cover_count).sanitized_for_filename

      create_findings_sheet_pdf organization, (cover_count += 1)

      cover_paths << absolute_findings_sheet_pdf_path(cover_count)
      cover_count += 1 if File.exist? cover_paths.last

      findings_dir = I18n.t('conclusion_review.bundle.findings_dir',
                            prefix: '%02d' % cover_count).sanitized_for_filename

      cover_count += 1 if findings.any?

      create_findings_follow_up_pdf organization, cover_count

      cover_paths << absolute_findings_follow_up_pdf_path(cover_count)
      cover_count += 1 if File.exist? cover_paths.last

      [cover_count, cover_paths, cois_dir, findings_dir]
    end

    def remove_covers cover_paths
      cover_paths.each do |cover|
        FileUtils.rm cover if File.exist? cover
      end
    end
end
