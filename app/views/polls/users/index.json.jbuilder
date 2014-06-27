json.array!(@users) do |user|
  json.extract! user, :id
  json.label user.to_s
end
