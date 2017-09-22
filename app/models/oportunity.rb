class Oportunity < Finding
  include Findings::Approval
  include Oportunities::Code
  include Oportunities::Defaults
  include Oportunities::SortColumns
  include Oportunities::Scopes
  include Oportunities::Validations
  include Oportunities::WorkPapers
end
