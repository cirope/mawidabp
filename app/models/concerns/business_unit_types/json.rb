module BusinessUnitTypes::Json
  extend ActiveSupport::Concern

  def as_json options = nil
    default_options = {
      only:    [:id],
      methods: [:label]
    }

    super default_options.merge(options || {})
  end
end
