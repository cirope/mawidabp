module Tags::Icons
  extend ActiveSupport::Concern

  included do
    ICONS = %w(
      asterisk
      ban
      bell
      bolt
      book
      bookmark
      briefcase
      bullhorn
      calendar
      camera
      chart-bar
      cloud
      cog
      comment
      compact-disc
      compress
      envelope
      exclamation-circle
      exclamation-triangle
      exclamation-triangle
      file
      film
      fire-alt
      flag
      folder
      folder-open
      font
      globe
      home
      image
      inbox
      info-circle
      leaf
      list-alt
      lock
      map-marker
      paperclip
      phone
      print
      question-circle
      random
      signal
      star
      tag
      tags
      thumbtack
      tree
      user
      video
      wrench
    )
  end

  def available_icons
    self.class.available_icons
  end

  module ClassMethods
    def available_icons
      ICONS
    end
  end
end
