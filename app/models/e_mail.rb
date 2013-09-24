class EMail < ActiveRecord::Base
  has_paper_trail

  # Constantes
  COLUMNS_FOR_SEARCH = HashWithIndifferentAccess.new(
    :to => {
      :column => "LOWER(#{EMail.table_name}.to)", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    },
    :subject => {
      :column => "LOWER(#{EMail.table_name}.subject)", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    }
  )
  # Default scope
  default_scope { order('created_at DESC') }

  # Restricciones
  validates :to, :subject, :presence => true

  # Relaciones
  belongs_to :organization
end
