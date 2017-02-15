class ResourceUtilization < ActiveRecord::Base
  include Auditable
  include Comparable
  include ParameterSelector
  include ResourceUtilizations::Resources
  include ResourceUtilizations::ResourceConsumers
  include ResourceUtilizations::Scopes
  include ResourceUtilizations::Validation

  def <=>(other)
    if other.kind_of?(ResourceUtilization)
      resource_id <=> other.resource_id
    else
      -1
    end
  end

  def human?
    resource_type == 'User'
  end

  def material?
    resource_type == 'Resource'
  end
end
