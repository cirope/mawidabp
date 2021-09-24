module ConclusionReviews::DefaultRtf
  extend ActiveSupport::Concern

  def default_rtf organization = nil, *args
    pat_rtf organization, *args
  end
end
