class OldPassword < ActiveRecord::Base
  # Named scopes
  scope :lasts, lambda { |user_id, result_limit|
    limit = result_limit - 1
    {
      :conditions => { :user_id => user_id },
      :order => 'created_at DESC',
      # En caso de ser 0 el límite no se busca ninguna contraseña anterior
      :limit => limit >= 0 ? limit : 0
    }
  }

  validates_length_of :password, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  
  # Relaciones
  belongs_to :user
end