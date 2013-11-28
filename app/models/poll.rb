class Poll < ActiveRecord::Base
  before_save :generate_access_token, :on => :create

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  attr_accessor :customer_name

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
    },
    :answered => {
      :column => "#{Poll.table_name}.answered", :operator => '=',
      :conversion_method => lambda { |value|
        if value.downcase == 'si'
          true
        elsif value.downcase == 'no'
          false
        else
          nil
        end
      }
    }
  )

  # Validaciones
  validates :organization_id, :questionnaire_id, :presence => true
  validates_length_of :comments, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  validates_format_of :customer_email, :with => EMAIL_REGEXP, :multiline => true,
    :allow_nil => true, :allow_blank => true
  validate :user_id_xor_customer_email

  # Relaciones
  belongs_to :questionnaire
  belongs_to :user
  belongs_to :organization
  belongs_to :pollable, :polymorphic => true
  has_many :answers, -> {
    includes(:question).order("#{Question.table_name}.sort_order ASC").references(:questions)
  }, :dependent => :destroy

  # Callbacks
  after_create :send_poll_email
  before_validation(:on => :update) do
    self.answered = true
  end
  # Named scopes
  scope :list, -> { where(organization_id: Organization.current_id) }
  scope :between_dates, ->(from, to) {
    list.where('created_at BETWEEN :from AND :to', :from => from, :to => to)
  }
  scope :by_questionnaire, ->(questionnaire_id) {
    list.where('questionnaire_id = :q_id', :q_id => questionnaire_id)
  }
  scope :answered, ->(answered) {
    where('answered = :answered', :answered => answered)
  }
  scope :pollables, -> {
    where('pollable_id IS NOT NULL')
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
    begin
      Notifier.pending_poll_email(self).deliver
    rescue Exception
      self.destroy
    end
  end

  private

  def user_id_xor_customer_email
    unless self.user_id.present? ^ self.customer_email.present?
      errors.add(:base, :invalid)
    end
  end

  def generate_access_token
    begin
      self.access_token = SecureRandom.hex
    end while self.class.exists?(:access_token => access_token)
  end
end
