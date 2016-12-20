module Tags::Icons
  extend ActiveSupport::Concern

  included do
    ICONS = %w(
      alert
      asterisk
      ban-circle
      bell
      book
      bookmark
      briefcase
      bullhorn
      calendar
      camera
      cd
      cloud
      cog
      comment
      compressed
      envelope
      exclamation-sign
      facetime-video
      file
      film
      fire
      flag
      flash
      folder-close
      folder-open
      font
      globe
      home
      inbox
      info-sign
      leaf
      list-alt
      lock
      map-marker
      paperclip
      phone-alt
      picture
      print
      pushpin
      question-sign
      random
      signal
      star
      stats
      tag
      tags
      tree-deciduous
      user
      warning-sign
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
