module WeaknessesHelper
  def show_weakness_previous_follow_up_dates(weakness)
    dates = weakness.all_follow_up_dates if weakness.being_implemented?
    list = String.new.html_safe
    out = String.new.html_safe

    unless dates.blank?
      dates.each { |d| list << content_tag(:li, l(d, :format => :long)) }

      out << link_to(t('weakness.previous_follow_up_dates'), '#', :onclick =>
        "$('#previous_follow_up_dates').slideToggle();return false;")

      out << content_tag(:div, content_tag(:ol, list),
        :id => 'previous_follow_up_dates', :style => 'display: none; margin-bottom: 1em;')

      content_tag(:div, out, :style => 'margin-bottom: 1em;')
    end
  end

  def next_weakness_work_paper_code(weakness, follow_up = false)
    review = weakness.control_objective_item.try(:review)
    code_prefix = follow_up ?
      t('code_prefixes.work_papers_in_weaknesses_follow_up') :
      weakness.work_paper_prefix

    code_from_review = review ?
      review.last_weakness_work_paper_code(code_prefix) :
      "#{code_prefix} 0".strip

    work_paper_codes = weakness.work_papers.reject(
      &:marked_for_destruction?).map(
      &:code).select { |c| c =~ /#{code_prefix}\s\d+/ }

    last_code = work_paper_codes.map do |code|
      code.match(/\d+\Z/)[0].to_i if code =~ /\d+\Z/
    end.compact.sort.last.to_i

    next_number = [code_from_review.match(/\d+\Z/)[0].to_i, last_code].max

    "#{code_prefix} #{next_number}"
  end

  def benefit_exists?
    Benefit.list.exists?
  end

  def weakness_achievements_for kind
    Benefit.list.where(kind: kind).order(created_at: :asc).map do |benefit|
      achievement = @weakness.achievements.detect { |a| a.benefit_id == benefit.id }

      achievement || @weakness.achievements.new(benefit_id: benefit.id)
    end
  end

  def weakness_business_units
    @weakness.control_objective_item.business_units
  end
end
