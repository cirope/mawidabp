module Weaknesses::Defaults
  extend ActiveSupport::Concern

  included do
    after_initialize :set_review_code, if: :new_record?
  end

  private

    def set_review_code
      self.review_code ||= next_code
    end
end
