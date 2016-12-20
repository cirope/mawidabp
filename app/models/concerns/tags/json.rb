module Tags::JSON
  extend ActiveSupport::Concern

  included do
    alias_attribute :label, :name
  end

  def as_json options = {}
    default_options = {
      only:    [:id],
      methods: [:label]
    }

    super default_options.merge(options)
  end
end
