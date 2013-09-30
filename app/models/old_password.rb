class OldPassword < ActiveRecord::Base
  validates :password, length: { maximum: 255 }, allow_nil: true, allow_blank: true
  
  # Relaciones
  belongs_to :user
end
