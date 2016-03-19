module Reviews::FindingCode
  extend ActiveSupport::Concern

  def next_finding_code prefix, findings
    last_review_code = findings.order(:review_code).last&.review_code || '0'
    last_number      = last_review_code.match(/\d+\Z/).to_a.first.to_i

    raise 'A review can not have more than 999 findings' if last_number > 999

    "#{prefix}#{'%.3d' % last_number.next}".strip
  end

  def next_weakness_code prefix = nil
    next_finding_code prefix, weaknesses.with_prefix(prefix)
  end

  def next_oportunity_code prefix = nil
    next_finding_code prefix, oportunities.with_prefix(prefix)
  end
end
