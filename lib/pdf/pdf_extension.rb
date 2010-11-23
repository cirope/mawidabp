module PDF
  module PDFClassExtension
    def relative_path(filename, sub_directory, id = 0)
      "/private/#{path_without_root(filename, sub_directory, id).join('/')}"
    end

    def absolute_path(filename, sub_directory, id = 0)
      path = [PRIVATE_PATH] + path_without_root(filename, sub_directory, id)
      
      File.join(*path)
    end

    def path_without_root(filename, sub_directory, id = 0)
      id_path = ('%08d' % id).scan(/..../)
      user_path = ('%08d' % (PaperTrail.whodunnit || 0)).scan(/..../)
      organization_path = ('%08d' %
        (GlobalModelConfig.current_organization_id || 0)).scan(/..../)

      organization_path + user_path + ['pdfs', sub_directory] + id_path +
        [filename]
    end

    def create_generic_pdf(orientation = :landscape, footer = true)
      pdf = PDF::Writer.new(:paper => PDF_PAPER, :orientation => orientation)

      pdf.margins_mm(*PDF_MARGINS)
      pdf.select_font 'Helvetica', :encoding => nil
      pdf.font_size = PDF_FONT_SIZE
      pdf.add_page_footer if footer

      pdf.open_object do |footer_object|
        font_size = (PDF_FONT_SIZE * 0.5).round

        pdf.add_image_from_file(PDF_LOGO, pdf.left_margin, 20,
          PDF_LOGO_SIZE.first, PDF_LOGO_SIZE.last)

        text = I18n.t :'app_copyright', :year => Date.today.year
        x_start = pdf.absolute_left_margin + font_size * 2 + PDF_LOGO_SIZE.first
        pdf.add_text(x_start, 20, text.to_iso, font_size)

        pdf.close_object
        pdf.add_object(footer_object, :all_pages)
      end

      pdf
    end
  end
  
  module PDFExtension
    def self.included(klass)
      klass.extend(PDFClassExtension)
    end

    def add_title(text, font_size = (PDF_FONT_SIZE * 1.5).round,
        justification = :full, underline = false)
      title_text = underline ? "<c:uline><b>#{text}</b></c:uline>" :
        "<b>#{text}</b>"
      self.text "#{title_text}\n", :font_size => font_size,
        :justification => justification
    end

    def add_subtitle(text, margin_top = 0, margin_down = 0,
        font_size = PDF_FONT_SIZE)
      self.move_pointer margin_top if margin_top != 0
      self.text "<c:uline><b>#{text.strip}</b></c:uline>",
        :font_size => font_size, :justification => :full
      self.move_pointer margin_down if margin_down != 0
    end

    def add_description_item(term, description, left = 0, underline = true,
        font_size = PDF_FONT_SIZE)
      if term && !term.blank? && description && !description.blank?
        term = underline ? "<c:uline><b>#{term}</b></c:uline>:" :
          "<b>#{term}</b>:"
        self.text "#{term} #{description}", :font_size => font_size,
          :left => left, :justification => :full
      end
    end

    def add_list(items, left = 0)
      self.move_pointer((self.font_size / 2.0).round)

      self.text items.to_a.map { |item| "<C:bullet /> #{item}" }.join("\n"),
        :left => left

      self.move_pointer((self.font_size / 2.0).round)
    end

    def add_organization_image(organization, font_size = PDF_FONT_SIZE)
      font_height_size = self.font_height(font_size)

      if organization.try(:image_model) &&
          File.exists?(organization.image_model.image.path(:thumb))
        self.add_image_from_file(
          organization.image_model.image.path(:thumb),
          self.left_margin, self.absolute_top_margin + font_height_size,
          organization.image_model.image_geometry(:pdf_thumb)[:width],
          organization.image_model.image_geometry(:pdf_thumb)[:height])
      end
    end

    def add_planning_header(organization, period)
      self.open_object do |heading|
        font_size = PDF_FONT_SIZE
        font_height_size = self.font_height(font_size)
        y_top = self.page_height - (self.top_margin / 2)

        self.add_organization_image organization, font_size

        text = "<b>#{I18n.t(:'pdf.period_description')}</b>: #{period.number}"
        x_start = self.absolute_right_margin - self.text_width(text, font_size)
        self.add_text(x_start, y_top - font_height_size, text.to_iso, font_size)

        text = I18n.l(Time.now.to_date, :format => :long)
        x_start = self.absolute_right_margin - self.text_width(text, font_size)
        self.add_text(x_start, y_top, text.to_iso, font_size)

        self.close_object
        self.add_object(heading, :all_pages)
      end
    end

    def add_review_header(organization, identification, project)
      self.open_object do |heading|
        font_size = PDF_FONT_SIZE
        font_height_size = self.font_height(font_size)
        y_top = self.page_height - (self.top_margin / 2)

        self.add_organization_image organization, font_size

        text = identification.blank? ? nil :
          "<b>#{I18n.t(:'pdf.review_identification')}</b>: #{identification}"
        x_start = self.absolute_right_margin - self.text_width(text, font_size)
        self.add_text(x_start, y_top, text.try(:to_iso), font_size)

        text = project
        x_start = self.absolute_right_margin - self.text_width(text, font_size)
        self.add_text(x_start, y_top - font_height_size, text.try(:to_iso),
          font_size)
        
        self.close_object
        self.add_object(heading, :all_pages)
      end
    end

    def add_review_auditors_table(review_user_assignments)
      unless review_user_assignments.blank?
        columns = {}
        column_data = {}

        review_user_assignments.each do |rua|
          columns[rua.id.to_s] = PDF::SimpleTable::Column.new(rua.id.to_s) do |c|
            c.heading = rua.type_text
            c.justification = :center
            c.width = self.percent_width(100 / review_user_assignments.size)
          end
        end

        review_user_assignments.each do |rua|
          column_data[rua.id.to_s] = "\n\n\n\n#{rua.user.full_name}".to_iso
        end

        unless column_data.blank?
          PDF::SimpleTable.new do |table|
            table.width = self.page_usable_width
            table.columns = columns
            table.data = [column_data]
            table.column_order = review_user_assignments.map{|rua| rua.id.to_s}
            table.font_size = (PDF_FONT_SIZE * 0.75).round
            table.shade_rows = :none
            table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
            table.heading_font_size = PDF_FONT_SIZE
            table.shade_headings = true
            table.position = :left
            table.orientation = :right
            table.render_on self
          end
        end
      end
    end

    def add_generic_report_header(organization, date = Date.today)
      self.open_object do |heading|
        font_size = PDF_FONT_SIZE
        y_top = self.page_height - (self.top_margin / 2)

        self.add_organization_image organization, font_size

        date_text = I18n.l(date, :format => :long) if date
        text = I18n.t :'follow_up_committee.print_date', :date => date_text
        x_start = self.absolute_right_margin - self.text_width(text, font_size)
        self.add_text(x_start, y_top, text.to_iso, font_size)

        self.close_object
        self.add_object(heading, :all_pages)
      end
    end

    def add_watermark(text, font_size = PDF_FONT_SIZE * 5)
      stroke_color = self.stroke_color?
      stroke_style = self.stroke_style?
      text_render_style = self.text_render_style?
      angle = ::Math.atan(self.page_height.to_f / self.page_width) *
        180.0 / ::Math::PI
      angle = angle < 0 || angle > 90 ? 60 : angle

      self.open_object do |watermark|
        self.stroke_color Color::RGB::Gray60
        self.stroke_style PDF::Writer::StrokeStyle.new(1, :cap => :butt,
          :join => :miter, :dash => PDF::Writer::StrokeStyle::SOLID_LINE)
        self.text_render_style 1
        
        text_width = self.text_width(text, font_size)
        y = text_width * ::Math.sin(angle)
        x = text_width * ::Math.cos(angle)

        self.add_text((self.absolute_x_middle + x).round,
          (self.absolute_y_middle + y / 2.0).round, text, font_size, angle)

        self.close_object

        self.add_object(watermark, :all_pages)

        self.stroke_color stroke_color
        self.stroke_style stroke_style
        self.text_render_style text_render_style
      end
    end

    def add_page_footer
      self.start_page_numbering self.absolute_right_margin, 20, 10, :right,
        I18n.t(:'pdf.page_pattern').to_iso, 1
    end

    def add_footnote(text, font_size = (PDF_FONT_SIZE * 0.75).round)
      font_height = self.font_height(font_size)
      self.add_text(self.absolute_left_margin,
        (self.bottom_margin - font_height * 5.5), text, font_size)
    end

    def page_usable_width
      self.page_width - self.right_margin - self.left_margin
    end

    def percent_width(width)
      (self.page_usable_width * (width / 100.0)).round
    end

    def custom_save_as(filename, sub_directory, id = 0)
      base_dir = File.join(*([PRIVATE_PATH] +
            PDF::Writer.path_without_root(filename, sub_directory, id)[0..-2]))

      FileUtils.makedirs base_dir
      self.save_as File.join(base_dir, filename)
    end
  end
end