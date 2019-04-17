class PlanResourcesPdf < Prawn::Document
  attr_reader :pdf

  def initialize title:, plan:, human_resource_utilizations:, current_organization:
    @current_organization                       = current_organization
    @title, @plan, @human_resource_utilizations = title, plan, human_resource_utilizations

    @pdf = Prawn::Document.create_generic_pdf :landscape
  end

  def relative_path
    Prawn::Document.relative_path pdf_name, Plan.table_name, random_id
  end

  def self.create attributes = nil
    _pdf = new attributes
    path = _pdf.send :generate

    FileRemoveJob.set(wait: 30.minutes).perform_later path

    _pdf
  end

  private

    def random_id
      @random_id ||= rand 99_999_999
    end

    def generate
      add_header
      add_body
      save
    end

    def add_header
      pdf.add_generic_report_header @current_organization
      pdf.add_title "#{@title} (#{Plan.model_name.human} #{@plan.period.name})"
    end

    def add_body
      @human_resource_utilizations.each do |resource_id, hrus|
        user = hrus.first.resource

        pdf.move_down PDF_FONT_SIZE * 1.5
        pdf.text user.full_name, size: (PDF_FONT_SIZE * 1.25).round, style: :bold

        put_resources hrus
      end
    end

    def put_resources hrus
      row_data = []

      hrus.each { |hru| row_data << row_data_for(hru) }

      put_resources_table row_data
    end

    def row_data_for hru
      [
        hru.resource_consumer.business_unit.to_s,
        hru.resource_consumer.project.to_s,
        I18n.l(hru.resource_consumer.start),
        I18n.l(hru.resource_consumer.end),
        hru.units.to_s
      ]
    end

    def put_resources_table row_data
      pdf.move_down PDF_FONT_SIZE

      if row_data.present?
        pdf.font_size (PDF_FONT_SIZE * 0.75).round do
          table_options = pdf.default_table_options column_widths

          pdf.table row_data.insert(0, column_headers), table_options do
            row(0).style(
              background_color: 'cccccc',
              padding: [
                (PDF_FONT_SIZE * 0.5).round,
                (PDF_FONT_SIZE * 0.3).round
              ]
            )
          end
        end
      end
    end

    def column_order
      [
        [PlanItem.human_attribute_name('business_unit_id'), 20],
        [PlanItem.human_attribute_name('project'), 45],
        [PlanItem.human_attribute_name('start'), 10],
        [PlanItem.human_attribute_name('end'), 10],
        [ResourceUtilization.human_attribute_name('units'), 15]
      ]
    end

    def column_headers
      column_order.map { |label, _with| "<b>#{label}</b>" }
    end

    def column_widths
      column_order.map { |_label, width| pdf.percent_width width }
    end

    def save
      pdf.custom_save_as pdf_name, Plan.table_name, random_id
    end

    def pdf_name
      "#{@title.downcase.gsub(/\s+/, '_')}.pdf".sanitized_for_filename
    end
end
