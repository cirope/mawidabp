require 'prawn/measurement_extensions'

module Prawn
  module Mawida
    module ClassExtension
      def relative_path(filename, sub_directory, id = 0)
        "/private/#{path_without_root(filename, sub_directory, id).join('/')}"
      end

      def absolute_path(filename, sub_directory, id = 0)
        path = [PRIVATE_PATH] + path_without_root(filename, sub_directory, id)

        File.join(*path)
      end

      def path_without_root(filename, sub_directory, id = 0)
        id_path = ('%08d' % id).scan(/\d{4}/)
        user_path = ('%08d' % (PaperTrail.whodunnit || 0)).scan(/\d{4}/)
        organization_path = ('%08d' %
          (Organization.current_id || 0)).scan(/\d{4}/)

        organization_path + user_path + ['pdfs', sub_directory] + id_path +
          [filename]
      end

      def create_generic_pdf(layout = :landscape, footer = true)
        pdf = Prawn::Document.new(
          :page_size => PDF_PAPER,
          :page_layout => layout,
          :margin => PDF_MARGINS.map(&:mm),
          :info => {:Creator => I18n.t(:app_name)}
        )

        pdf.font 'Helvetica', :size => PDF_FONT_SIZE

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

      def add_title(text, font_size = 18, align = :left, underline = false)
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

      def add_description_item(term, description, left = 0, underline = true, font_size = 12)
        if term.present? && description.present?
          options = { invalid: :replace, undef: :replace, replace: '?' }
          formated_term = underline ? "<u><b>#{term}</b></u>" : "<b>#{term}</b>"
          encoded_text = "#{formated_term}: #{description}".encode 'windows-1252', 'UTF-8', options

          self.text encoded_text, :size => font_size,
            :inline_format => true, :indent_paragraphs => left.pt
        end
      end

      def add_list(items, left = 0)
        margin = (self.font_size.pt / 2.0).round.pt
        string = items.to_a.map { |item| "• #{item}" }.join("\n")

        self.move_down margin

        self.text string, :indent_paragraphs => left.pt, :inline_format => true

        self.move_down margin
      end

      def add_organization_image(organization, font_size = 10)
        organization_image = organization.try(:image_model).try(:image).try(
          :thumb).try(:path)
        if organization_image && File.exists?(organization_image)
          image_geometry = organization.image_model.image_geometry(:pdf_thumb)
          self.image organization_image,
            :at => [0, self.bounds.top + (font_size.pt * 2) + image_geometry[:height]],
            :width => image_geometry[:width], :height => image_geometry[:height]
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

            self.text_box extra_text, :at => coordinates, :size => font_size,
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

            self.text_box extra_text, :at => coordinates, :size => font_size,
              :width => (coordinates[0] - PDF_MARGINS[1].mm), :align => :right
          end

          self.y = y_pointer
        end
      end

      def add_review_signatures_table(review_user_assignments)
        if review_user_assignments.present?
          column_data = [[]]
          column_headers = []
          column_widths = []

          review_user_assignments.each do |rua, i|
            column_headers << "<b>#{rua.type_text}</b>"
            column_data[0] << "\n\n\n\n#{rua.user.full_name}"
            column_widths << self.percent_width(
              100.0 / review_user_assignments.size)
          end

          font_size(((PDF_FONT_SIZE * 0.75).round).pt) do
            table_options = {
              :header => true,
              :cell_style => {
                :padding => (PDF_FONT_SIZE * 0.3).round,
                :inline_format => true
              },
              :width => column_widths.sum,
              :column_widths => column_widths
            }

            table(column_data.insert(0, column_headers), table_options) do
              row(0).style(
                :background_color => 'cccccc',
                :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
              )
            end
          end
        end
      end

      def add_generic_report_header(organization, date = Date.today, text = nil)
        y_pointer = self.y

        self.repeat :all do
          font_size = PDF_HEADER_FONT_SIZE

          self.add_organization_image organization, font_size

          if show_print_date_on? organization
            self.canvas do
              date_text = I18n.l(date, :format => :long) if date
              text ||= I18n.t(:'follow_up_committee.print_date',
                :date => date_text)
              coordinates = [
                self.bounds.width / 2.0,
                self.bounds.top - font_size.pt * 2
              ]

              self.text_box text, :at => coordinates, :size => font_size,
                :width => (coordinates[0] - PDF_MARGINS[1].mm), :align => :right
            end
          end
        end

        self.y = y_pointer
      end

      def add_watermark(text, font_size = 60)
        y_pointer = self.y

        self.repeat :all do
          self.canvas do
            fill_color, self.fill_color = self.fill_color, '707070'

            self.transparent 0.5, 0.75 do
              self.text_box text, :align => :center, :valign => :center,
                :size => font_size
            end

            self.fill_color fill_color
          end
        end

        self.y = y_pointer
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

      def add_footnote(text, font_size = 8, style = :normal)
        font_height = self.font.height_at(font_size)

        self.draw_text(text, :size => font_size, :style => style,
          :at => [self.bounds.left, self.bounds.bottom - font_height])
      end

      def default_table_options(column_widths)
        {
          :cell_style => {
            :padding => (PDF_FONT_SIZE * 0.3).round,
            :inline_format => true,
            :overflow => false
          },
          :width => column_widths.sum,
          :row_colors => %w[ffffff ececec],
          :column_widths => column_widths,
          :header => true
        }
      end

      def page_usable_width
        bounds.width
      end

      def percent_width(width)
        (page_usable_width * (width / 100.0)).round
      end

      def custom_save_as(filename, sub_directory, id = 0)
        base_dir = File.join(*([PRIVATE_PATH] + Prawn::Document.path_without_root(
              filename, sub_directory, id)[0..-2]))
        file_path = File.join base_dir, filename

        FileUtils.makedirs base_dir
        self.save_as file_path

        file_path
      end

      private

        def show_print_date_on? organization
          setting = organization.settings.find_by name: 'show_print_date_on_pdfs'

          (setting ? setting.value : DEFAULT_SETTINGS[:show_print_date_on_pdfs][:value]) != '0'
        end
    end
  end
end
