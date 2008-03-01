module FollowUpCommitteeHelper
  def weighted_average(data)
    result = []

    if data.kind_of?(Hash)
      data.each { |_, v| result << weighted_average(v) }
    elsif data.kind_of?(Array)
      total_count = data.inject(0) { |t, n| t + n[1] }
      result << data.inject(0) { |t, n| t + n[0] * n[1] } / total_count
    end

    result.inject { |t, n| t + n } / result.size
  end

  def prepare_risk_levels(all_risks)
    risks = []

    all_risks.each do |risk_model|
      risk_model.value.each do |risk|
        cleaned_risk = [risk[0], risk[1].to_i]
        
        risks << cleaned_risk unless risks.include?(cleaned_risk)
      end
    end

    risks
  end
end