# -*- coding: utf-8 -*-
require 'prawn/measurement_extensions'

module Prawn
  module Mawida
    module ClassExtension
      def relative_path(filename, sub_directory, id = 0)
        "/private/pdfs/#{sub_directory}/" + ('%08d' % id).scan(/..../).join('/') +
          "/#{filename}"
      end

      def absolute_path(filename, sub_directory, id = 0)
        path = [PRIVATE_PATH, 'pdfs', sub_directory] +
          ('%08d' % id).scan(/..../) + [filename]
        File.join(*path)
      end

      def create_generic_pdf(layout = :landscape, footer = true)
        pdf = Prawn::Document.new(
          :page_size => PDF_PAPER,
          :page_layout => layout,
          :margin => PDF_MARGINS.map(&:mm)
        )

        pdf.font 'Helvetica'

        pdf.repeat :all do
          font_size = 6

          pdf.image PDF_LOGO, :at => [pdf.bounds.left, -PDF_LOGO_SIZE.last.pt],
            :width => PDF_LOGO_SIZE.first, :height => PDF_LOGO_SIZE.last

          text = I18n.t :'app_copyright', :year => Date.today.year
          x_start = pdf.bounds.left + font_size.pt * 2 + PDF_LOGO_SIZE.first.pt
          pdf.draw_text(text, :at => [x_start, -(PDF_LOGO_SIZE.last.pt * 2)],
            :size => font_size)
        end

        pdf.add_page_footer if footer

        pdf
      end
    end

    module Extension
      def self.included(klass)
        klass.extend(ClassExtension)
      end

      def add_title(text, font_size = 18, align = :justify, underline = false)
        title_text = underline ? "<u><b>#{text}</b></u>" :  "<b>#{text}</b>"

        self.text "#{title_text}\n", :size => font_size, :align => align,
          :inline_format => true
      end

      def add_subtitle(text, margin_top = 0, margin_down = 0, font_size = 12)
        self.move_down margin_top.pt if margin_top != 0
        self.text "<u><b>#{text.strip}</b></u>", :size => font_size,
          :inline_format => true
        self.move_down margin_down.pt if margin_down != 0
      end

      def add_description_item(term, description, left = 0, underline = true,
          font_size = 12)
        if term && !term.blank? && description && !description.blank?
          term = underline ? "<u><b>#{term}</b></u>" : "<b>#{term}</b>"

          self.text "#{term}: #{description}", :size => font_size,
            :inline_format => true, :indent_paragraphs => left.pt
        end
      end

      def add_list(items, left = 0)
        margin = (self.font_size.pt / 2.0).round.pt
        string = items.to_a.map { |item| "• #{item}" }.join("\n")

        self.move_down margin

        self.text string, :indent_paragraphs => left.pt

        self.move_down margin
      end

      def add_organization_image(organization, font_size = 10)
        if organization && organization.image_model
          organization_image = organization.image_model.thumb(:pdf_thumb)

          self.image organization.image_model.full_filename(:thumb),
            :at => [0, self.bounds.top + (font_size.pt * 2) +
                organization_image.height],
            :width => organization_image.width,
            :height => organization_image.height
        end
      end

      def add_planning_header(organization, period)
        self.repeat :all do
          font_size = PDF_HEADER_FONT_SIZE

          self.add_organization_image organization, font_size

          y_pointer = self.y

          self.canvas do
            coordinates = [
              self.bounds.width / 2.0,
              self.bounds.top - font_size.pt * 2
            ]

            extra_text = [
              I18n.t(:'pdf.period_description', :period => period.number),
              I18n.l(Time.now.to_date, :format => :long)
            ].join("\n")

            self.text_box extra_text, :at => coordinates,
              :width => (coordinates[0] - PDF_MARGINS[1].mm), :align => :right
          end

          self.y = y_pointer
        end
      end

      def add_review_header(organization, identification, project)
        self.repeat :all do
          font_size = PDF_HEADER_FONT_SIZE

          self.add_organization_image organization, font_size

           y_pointer = self.y

          self.canvas do
            review = identification ? I18n.t(:'pdf.review_identification',
              :review => identification) : nil
            coordinates = [
              self.bounds.width / 2.0,
              self.bounds.top - font_size.pt * 2
            ]

            extra_text = [review, project].compact.join("\n")

            self.text_box extra_text, :at => coordinates,
              :width => (coordinates[0] - PDF_MARGINS[1].mm), :align => :right
          end

          self.y = y_pointer
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

          review_user_assignments.each do |rua|pdf.render_file 'test.pdf'

            column_data[rua.id.to_s] = "\n\n\n\n#{rua.user.full_name}"
          end

          unless column_data.blank?
            PDF::SimpleTable.new do |table|
              table.width = self.page_usable_width
              table.columns = columns
              table.data = [column_data]
              table.column_order = review_user_assignments.map{|rua| rua.id.to_s}
              table.font_size = 8
              table.shade_rows = :none
              table.shade_heading_color = Color::RGB::Grey70
              table.heading_font_size = 10
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
          font_size = 12
          y_top = self.page_height - (self.top_margin / 2)

          self.add_organization_image organization, font_size

          date_text = I18n.l(date, :format => :long) if date
          text = I18n.t :'follow_up_committee.print_date', :date => date_text
          x_start = self.absolute_right_margin - self.text_width(text, font_size)
          self.add_text(x_start, y_top, text, font_size)

          self.close_object
          self.add_object(heading, :all_pages)
        end
      end

      def add_watermark(text, font_size = 60)
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

      def add_page_footer(font_size = 10)
        self.repeat :all, :dynamic =>  true do
          string = I18n.t(:'pdf.page_pattern', :page => self.page_number,
            :total => self.page_count)

          self.draw_text string, :at =>
            [self.bounds.right - self.width_of(string), -(font_size.pt * 3)],
            :size => font_size
        end
      end

      def add_footnote(text, font_size = 8)
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
        base_dir = File.join "#{PRIVATE_PATH}pdfs", sub_directory,
          *('%08d' % id).scan(/..../)
        FileUtils.makedirs base_dir
        self.save_as File.join(base_dir, filename)
      end
    end
  end
end
