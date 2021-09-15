json.array!(@users) do |user|
  json.extract! user, :id, :label, :informal, :can_act_as_audited?
end
