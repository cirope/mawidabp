module PaperTrail
  class Version < ActiveRecord::Base
    attr_accessible :organization_id, :important, :event, :whodunnit
  end
end
