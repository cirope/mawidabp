class LoginRecord < ActiveRecord::Base
  include ParameterSelector

  has_paper_trail meta: { organization_id: -> { Organization.current_id } }

  default_scope -> { where(organization_id: Organization.current_id) }

  # Constantes
  COLUMNS_FOR_SEARCH = HashWithIndifferentAccess.new({
    :user => {
      :column => "LOWER(#{User.table_name}.user)", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    },
    :data => {
      :column => "LOWER(#{table_name}.data)", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    }
  })

  attr_accessor :request

  # Restricciones
  validates :user_id, :organization_id, :start, :presence => true
  validates_datetime :start, :allow_nil => true, :allow_blank => true
  validates_datetime :end, :allow_nil => true, :allow_blank => false,
    :after => :start

  # Relaciones
  belongs_to :user
  belongs_to :organization

  def initialize(attributes = nil, options = {})
    super(attributes, options)

    self.start ||= Time.now

    if self.request
      self.data ||= "IP: [#{self.request.ip}], B: [#{self.request.user_agent}]"
    end
  end

  def end!
    self.update_attribute :end, Time.now
  end
end
