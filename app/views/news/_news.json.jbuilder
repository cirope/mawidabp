json.extract! news, :id, :title, :description, :body, :published_at, :organization_id, :group_id, :created_at, :updated_at
json.url news_url(news, format: :json)