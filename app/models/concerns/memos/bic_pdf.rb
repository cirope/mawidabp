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

    pdf.image File.join(Rails.root,
                        'app',
                        'assets',
                        'images',
                        'memo',
                        'bice_fidecomiso.jpg'),
              position: :left, scale: 0.75

    pdf.move_down 38
    pdf.text  '<font name="Helvetica"><color rgb="#008385">' + "#{sprintf('%02d', id)}/#{created_at.year}" + '</color></font>',
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
          content: '<font name="Helvetica" size="16"><color rgb="#182d34"><b>REQUERIDO POR</b></color></font>     <font name="Helvetica" size="16"><color rgb="#aaaaaa">' + required_by + '</color></font>',
          inline_format: true,
          border_width: [0, 0, 0, 4],
          border_left_color: '008385',
          padding_left: 25
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
          content: '<font name="Helvetica" size="16"><color rgb="#182d34"><b>COMENTARIOS</b></color></font>                      <font name="Helvetica" size="16"><color rgb="#aaaaaa">' + description + '</color></font>',
          inline_format: true,
          border_width: [0, 0, 0, 4],
          border_left_color: '008385',
          padding_left: 25,
          height: 140
        }
      ]
    ], column_widths: [95, 60, 200, 205]

    pdf.move_down 100
    pdf.text '<font name="Helvetica" size="16"><color rgb="#008385"><b>PROYECTO</b></color></font>', 
             inline_format: true,
             indent_paragraphs: 165

    pdf.move_down 5
    pdf.table [
      [
        {
          content: '', border_width: [0, 0, 0, 0]
        },
        {
          content: '<font name="Helvetica" size="35"><color rgb="#182d34"><b>' + name + '</b></color></font>',
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
end
