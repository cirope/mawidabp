module GlobalModelConfig
  def self.included(base)
    base.before_action :set_current_organization_id
  end

  def self.current_organization_id
    GlobalModelConfig.config_store[:organization_id].respond_to?(:call) ?
      GlobalModelConfig.config_store[:organization_id].call :
      GlobalModelConfig.config_store[:organization_id]
  end

  def self.current_organization_id=(value)
    GlobalModelConfig.config_store[:organization_id] = value
  end

  def self.config_store
    Thread.current[:mawida] ||= {}
  end

  private
    def set_current_organization_id
      GlobalModelConfig.config_store[:organization_id] = lambda {
        self.respond_to?(:current_organization) ? self.current_organization : nil
      }
    end
end
