module GlobalModelConfig
  @@current_organization_id = nil

  def self.included(base)
    base.before_filter :set_current_organization_id
  end

  def self.current_organization_id
    @@current_organization_id.respond_to?(:call) ?
      @@current_organization_id.call : @@current_organization_id
  end

  def self.current_organization_id=(value)
    @@current_organization_id = value
  end

  private

  def set_current_organization_id
    @@current_organization_id = lambda {
      self.respond_to?(:current_organization) ? self.current_organization : nil
    }
  end
end