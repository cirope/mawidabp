class Poll < ActiveRecord::Base
  before_save :generate_access_token, :on => :create

  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }
  # Constantes
  COLUMNS_FOR_SEARCH = HashWithIndifferentAccess.new(
    :name => {
      :column => "LOWER(#{User.table_name}.name)", :operator => 'ILIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    },
    :last_name => {
      :column => "LOWER(#{User.table_name}.last_name)", :operator => 'ILIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    },
    :questionnaire_name => {
      :column => "LOWER(#{Questionnaire.table_name}.name)", :operator => 'ILIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    }
  )

  # Validaciones
  validates :organization_id, :questionnaire_id, :user_id, :presence => true
  validates_length_of :comments, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  # Relaciones
  belongs_to :questionnaire
  belongs_to :user
  belongs_to :organization
  belongs_to :pollable, :polymorphic => true
  has_many :answers, :include => :question, :dependent => :destroy, :order => "#{Question.table_name}.sort_order ASC"
  # Callbacks
  after_create :send_poll_email
  before_validation(:on => :update) do
    self.answered = true
  end
  # Named scopes
  scope :list, lambda {
    where(:organization_id => GlobalModelConfig.current_organization_id)
  }
  scope :by_questionnaire, lambda {
    |questionnaire_id| where('questionnaire_id = :q_id AND organization_id = :o_id',
      :q_id => questionnaire_id, :o_id => GlobalModelConfig.current_organization_id)
  }
  scope :by_organization, lambda {
    |org_id, poll_id| where('id = :poll_id AND organization_id = :org_id', :org_id => org_id, :poll_id => poll_id)
  }
  scope :by_user, lambda {
    |user_id, org_id, id| where('id = :id AND organization_id = :org_id AND user_id = :user_id',
      :org_id => org_id, :id => id, :user_id => user_id
      )
  }

  accepts_nested_attributes_for :answers

  def initialize(attributes = nil, options = {})
    super(attributes, options)

    if self.questionnaire && self.answers.empty?
      self.questionnaire.questions.each do |question|
        self.answers.build(:question => question)
      end
    end
  end

  def send_poll_email
    Notifier.pending_poll_email(self).deliver
  end

  private

  def generate_access_token
    begin
      self.access_token = SecureRandom.hex
    end while self.class.exists?(:access_token => access_token)

    Rails.logger.debug "ACCESS TOKEN: #{self.access_token}"
  end

end
