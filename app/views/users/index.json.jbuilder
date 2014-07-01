json.array!(@users) do |user|
  json.extract! user, :id, :label, :informal, :cost_per_unit, :can_act_as_audited?
end
