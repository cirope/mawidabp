module Memos::CloseDate
  extend ActiveSupport::Concern

  def readonly_fields?
    new_record? ? false : close_date_was < Date.today
  end
end
