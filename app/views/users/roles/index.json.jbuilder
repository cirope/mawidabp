json.array!(@roles) do |role|
  json.array! [role.name, role.id]
end
