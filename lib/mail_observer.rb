class MailObserver
  def self.delivered_email(message)
    body = message.body.decoded.present? ? message.body.decoded :
      message.parts.detect { |p| p.content_type.match(/text/) }.try(:body).try(:decoded)
    
    EMail.create!(
      :to => message.to.join(', '),
      :subject => message.subject,
      :body => body,
      :attachments => message.attachments.map(&:filename).join('; ')
    )
  end
end