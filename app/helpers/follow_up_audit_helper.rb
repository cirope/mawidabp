module FollowUpAuditHelper
  def weaknesses_brief_audit_users weakness
    weakness.
      finding_user_assignments.
      select { |fua| fua.user.can_act_as_audited? }.
      map(&:user).
      map(&:full_name)
  end

  def distance_in_days_to_cut_date weakness
    if weakness.first_follow_up_date
      distance = (@cut_date - weakness.first_follow_up_date).days / 1.day

      distance.abs.to_i > 365 ? distance.abs.to_i : nil
    end
  end
end
