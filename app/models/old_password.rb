class OldPassword < ActiveRecord::Base
  # Named scopes
  scope :lasts, lambda { |user_id, result_limit|
    limit = result_limit - 1
    
    where(:user_id => user_id).order('created_at DESC').limit(
      limit >= 0 ? limit : 0
    )
  }

  validates :password, :length => {:maximum => 255}, :allow_nil => true,
    :allow_blank => true
  
  # Relaciones
  belongs_to :user
end