class Current < ActiveSupport::CurrentAttributes
  attribute :organization,
            :group,
            :corporate_ids,
            :user,
            :conclusion_pdf_format
end
