class Current < ActiveSupport::CurrentAttributes
  attribute :organization,
            :group,
            :corporate_ids,
            :user,
            :conclusion_pdf_format,
            :settings,
            :global_weakness_code

end
