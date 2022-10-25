module Memos::DefaultPdf
  extend ActiveSupport::Concern

  def default_pdf
    pdf = Prawn::Document.new page_layout: :portrait

    pdf.custom_save_as pdf_name, Memo.table_name, id
  end
end
