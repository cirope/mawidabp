module WeaknessTemplates::JSON
  extend ActiveSupport::Concern

  included do
    alias_attribute :label, :title
  end

  def as_json options = nil
    default_options = {
      only:    [:id],
      methods: [:label]
    }

    super default_options.merge(options || {})
  end
end
