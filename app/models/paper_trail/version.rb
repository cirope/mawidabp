module PaperTrail
  class Version < ActiveRecord::Base
    include PaperTrail::VersionConcern

    attribute :important, :boolean
  end
end
