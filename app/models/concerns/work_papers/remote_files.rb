module WorkPapers::RemoteFiles
  extend ActiveSupport::Concern

  GOOGLE_DRIVE_REGEXP = /https:\/\/docs.google.com\/[\\\w\-.:%]+(\/\S*)?/

  def to_remote_url
    description.match(GOOGLE_DRIVE_REGEXP) && $~[0]
  end
end
