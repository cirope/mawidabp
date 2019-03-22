module Reviews::Reorder
  extend ActiveSupport::Concern

  def reorder
    order         = 0
    sorted_groups = grouped_control_objective_items.to_a.sort do |group1, group2|
      pc1 = group1.first
      pc2 = group2.first

      if pc1.name.to_f > 0 && pc2.name.to_f > 0
        pc1.name.to_f <=> pc2.name.to_f
      else
        pc1.name <=> pc2.name
      end
    end

    sorted_groups.each do |pc, cois|
      cois.sort_by(&:control_objective_text).each do |coi|
        coi.order_number = order += 1
      end
    end

    save
  end
end
