module Reviews::Overrides
  extend ActiveSupport::Concern

  def to_s
    "#{long_identification } (#{I18n.l issue_date, format: :minimal})"
  end
end
