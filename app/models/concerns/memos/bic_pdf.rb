module Memos::BicPdf
  extend ActiveSupport::Concern

  def bic_pdf
    pdf = Prawn::Document.new page_layout: :portrait,
                              background: File.join(Rails.root,
                                                    'app',
                                                    'assets',
                                                    'images',
                                                    'memo',
                                                    'background.png'),
                              margin: [0, 0]

    if Current.organization.prefix == 'bic-fi'
      pdf.image File.join(Rails.root,
                          'app',
                          'assets',
                          'images',
                          'memo',
                          'bice_fidecomiso.jpg'),
                position: :left, scale: 0.75
    else
      pdf.move_down 37
    end

    pdf.move_down 38
    pdf.text text_with_style(text: "#{sprintf('%02d', id)}/#{created_at.year}",
                             font: 'Helvetica',
                             color: '#008385'),
             align: :left,
             indent_paragraphs: 62,
             size: 37,
             inline_format: true,
             character_spacing: 1

    pdf.move_down 55
    pdf.image File.join(Rails.root, 'app', 'assets', 'images', 'memo', 'bice_logo.jpg'), 
              scale: 0.32, position: 62

    pdf.move_down 20
    pdf.table [
      [
        {
          content: '', border_width: [0, 0, 0, 0]
        },
        {
          image: File.join(Rails.root, 'app', 'assets', 'images', 'memo', 'iram_icono.jpg'), 
          scale: 0.33,
          border_width: [0, 0, 0, 0],
          padding_top: 15
        },
        {
          image: File.join(Rails.root, 'app', 'assets', 'images', 'memo', 'sigen_icono.jpg'), 
          scale: 0.33,
          border_width: [0, 0, 0, 0]
        },
        {
          content: "#{text_with_style(text: Memo.human_attribute_name('plan_item').upcase, font: 'Helvetica', size: '16', color: '#182d34', bold: true)}             #{text_with_style(text: name, font: 'Helvetica', size: '16', color: '#aaaaaa')}",
          inline_format: true,
          border_width: [0, 0, 0, 4],
          border_left_color: '008385',
          padding_left: 25,
          height: 105
        }
      ]
    ], column_widths: [95, 60, 200, 205]

    pdf.move_down 20
    pdf.table [
      [
        {
          content: '', border_width: [0, 0, 0, 0]
        },
        {
          content: '', border_width: [0, 0, 0, 0]
        },
        {
          content: '', border_width: [0, 0, 0, 0]
        },
        {
          content: "#{text_with_style(text: Memo.human_attribute_name('required_by').upcase, font: 'Helvetica', size: '16', color: '#182d34', bold: true)}     #{text_with_style(text: (manual_required_by ? required_by_text : required_by), font: 'Helvetica', size: '16', color: '#aaaaaa')}",
          inline_format: true,
          border_width: [0, 0, 0, 4],
          border_left_color: '008385',
          padding_left: 25,
          height: 105
        }
      ]
    ], column_widths: [95, 60, 200, 205]

    pdf.move_down 100
    pdf.text text_with_style(text: I18n.t('memo.description_pdf'),
                             font: 'Helvetica',
                             size: '16',
                             color: '#008385',
                             bold: true),
             inline_format: true,
             indent_paragraphs: 165

    pdf.move_down 5
    pdf.table [
      [
        {
          content: '', border_width: [0, 0, 0, 0]
        },
        {
          content: text_with_style(text: (description || ''),
                                   font: 'Helvetica',
                                   size: '13',
                                   color: '#182d34',
                                   bold: true),
          inline_format: true,
          border_width: [0, 0, 0, 0]
        },
        {
          content: '', border_width: [0, 0, 0, 0]
        }
      ]
    ], column_widths: [158, 270, 30]

    pdf.custom_save_as pdf_name, Memo.table_name, id
  end

  private

    def text_with_style(text: nil, font: nil, size: nil, color: nil, bold: false)
      "#{font_open_tag(font, size)}#{text_content(text, color, bold)}</font>"
    end

    def font_open_tag(font, size)
      return "<font name='#{font}' size='#{size}'>" if font.present? && size.present?
      return "<font name='#{font}'>" if font.present?
      return "<font size='#{size}'>" if size.present?

      '<font>'
    end

    def text_content(text, color, bold)
      return "<color rgb='#{color}'><b>#{text}</b></color>" if color.present? && bold
      return "<color rgb='#{color}'>#{text}</color>" if color.present?
      return "<b>#{text}</b>" if bold

      text
    end
end
