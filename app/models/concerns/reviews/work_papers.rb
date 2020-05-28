module Reviews::WorkPapers
  extend ActiveSupport::Concern

  def last_control_objective_work_paper_code prefix: nil
    work_papers = []

    control_objective_items.each do |coi|
      work_papers.concat coi.work_papers.with_prefix(prefix)
    end

    last_work_paper_code prefix, work_papers
  end

  def last_weakness_work_paper_code prefix: nil
    work_papers = []

    (weaknesses + final_weaknesses).each do |w|
      work_papers.concat w.work_papers.with_prefix(prefix)
    end

    last_work_paper_code prefix, work_papers
  end

  def last_oportunity_work_paper_code prefix: nil
    work_papers = []

    (oportunities + final_oportunities).each do |w|
      work_papers.concat w.work_papers.with_prefix(prefix)
    end

    last_work_paper_code prefix, work_papers
  end

  def work_papers
    work_papers = []

    control_objective_items.each do |coi|
      work_papers.concat coi.work_papers
    end

    (weaknesses + final_weaknesses).each do |w|
      work_papers.concat w.work_papers
    end

    (oportunities + final_oportunities).each do |w|
      work_papers.concat w.work_papers
    end

    work_papers
  end

  def recode_work_papers
    work_papers = self.work_papers.sort_by &:code
    codes       = {}

    WorkPaper.transaction do
      work_papers.each do |work_paper|
        prefix, code_number = work_paper.code.split
        codes[prefix]     ||= 1

        if codes[prefix] != code_number.to_i
          work_paper.update! code: "#{prefix} #{'%.3d' % codes[prefix]}"
        end

        codes[prefix] += 1
      end
    end
  end

  private

    def last_work_paper_code prefix, work_papers
      last_code   = work_papers.map { |wp| wp.code[/\d+\Z/].to_i }.sort.last
      last_number = last_code.blank? ? 0 : last_code

      "#{prefix} #{'%.3d' % last_number}"
    end
end
