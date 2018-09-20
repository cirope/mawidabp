require 'application_responder'

module FlashResponders
  extend ActiveSupport::Concern

  included do
    respond_to :html

    self.responder = ApplicationResponder
  end
end
