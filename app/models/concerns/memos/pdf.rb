module Memos::Pdf
  extend ActiveSupport::Concern

  def to_pdf
    send "#{Current.conclusion_pdf_format}_pdf"
  end

  def absolute_pdf_path
    Prawn::Document.absolute_path pdf_name, Memo.table_name, id
  end

  def relative_pdf_path
    Prawn::Document.relative_path pdf_name, Memo.table_name, id
  end

  def pdf_name
    identification = name.strip.sanitized_for_filename[0..120]
    model_name     = Memo.model_name.human.downcase.gsub /\s/, '_'

    "#{model_name}-#{identification}.pdf"
  end
end
