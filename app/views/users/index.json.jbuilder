json.array!(@users) do |user|
  json.extract! user, :id, :label, :informal
end
