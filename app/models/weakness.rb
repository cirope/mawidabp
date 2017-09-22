class Weakness < Finding
  include Weaknesses::Approval
  include Weaknesses::Code
  include Weaknesses::Defaults
  include Weaknesses::GraphHelpers
  include Weaknesses::Priority
  include Weaknesses::Risk
  include Weaknesses::Scopes
  include Weaknesses::Validations
  include Weaknesses::WorkPapers
end
