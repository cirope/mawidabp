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
  scope :list, -> {
    where(:organization_id => GlobalModelConfig.current_organization_id)
  }
  scope :between_dates, ->(from, to) {
    where('created_at BETWEEN :from AND :to AND organization_id = :o_id',
      :from => from, :to => to, :o_id => GlobalModelConfig.current_organization_id)
  }
  scope :by_questionnaire, ->(questionnaire_id) {
    where('questionnaire_id = :q_id AND organization_id = :o_id',
      :q_id => questionnaire_id, :o_id => GlobalModelConfig.current_organization_id)
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

  def name
    if self.pollable_id.present?
      "#{self.questionnaire.name} (#{self.pollable_type.constantize.model_name.human})"
    elsif self.questionnaire.id == 4 # Comité
      "#{self.questionnaire.name} (#{I18n.t 'questionnaire.monthly_committee'})"
    else
      "#{self.questionnaire.name} (#{I18n.t 'questionnaire.general'})"
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
