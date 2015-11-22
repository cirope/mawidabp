module Periods::Overrides
  extend ActiveSupport::Concern
  include Comparable

  def to_s
    "#{description} (#{number})"
  end

  def inspect
    "#{number} (#{dates_range_text})"
  end

  def start
    super.try :to_date
  end

  def end
    super.try :to_date
  end

  def <=>(other)
    if other.kind_of?(Period)
      start_result = start <=> other.start
      end_result = self.end <=> other.end if start_result == 0

      end_result || start_result
    else
      -1
    end
  end

  def contains? date
    date.respond_to?(:between?) && date.between?(start, self.end)
  end

  def dates_range_text short = true
    short ? short_dates_range_text : long_dates_range_text
  end

  private

    def short_dates_range_text
      "#{I18n.l(start, format: :minimal)} -> #{I18n.l(self.end, format: :minimal)}"
    end

    def long_dates_range_text
      start_text = "#{Period.human_attribute_name('start')}: #{I18n.l(start, format: :long)}"
      end_text   = "#{Period.human_attribute_name('end')}: #{I18n.l(self.end, format: :long)}"

      "#{start_text} | #{end_text}"
    end
end
