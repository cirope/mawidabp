module Weaknesses::Defaults
  extend ActiveSupport::Concern

  included do
    after_initialize :set_review_code, if: :new_record?
    before_validation :set_priority, if: -> { SHOW_CONDENSED_PRIORITIES }
  end

  private

    def set_review_code
      self.review_code ||= next_code
    end

    def set_priority
      if risk != Finding.risks[:medium] || (Current.conclusion_pdf_format == "gal" &&
        risk == Finding.risks[:medium] && self.priority.nil?)
          self.priority = Finding.priorities[:low]
      end
    end
end
