# frozen_string_literal: true

require 'net/http'

class EmailReceiverStrategies::MGraphStrategy < EmailReceiverStrategies::EmailReceiverStrategy
  def initialize; end;

  def fetch
    all.each do |mail|
      begin
        Finding.receive_mail mail

        set_read_email mail
      rescue Exception => exception
        log exception, mail
      end
    end
  end

  def clean_answer mail
    regex        = Regexp.new(ENV['REGEX_REPLY_EMAIL'], Regexp::MULTILINE)
    clean_answer = mail.body.split regex

    clean_answer.present? ? clean_answer.first : '-'
  end

  private

    def all
      uri      = URI("https://graph.microsoft.com/v1.0/users/#{ENV['EMAIL_USER_ID']}/messages?$filter=isRead eq false")
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.get uri, authorized_request_headers
      end

      json_response = JSON.parse response.body

      json_response['value'].map do |json_mail|
        OpenStruct.new id: json_mail['id'],
                       subject: json_mail['subject'],
                       from: [json_mail['from']['emailAddress']['address']],
                       body: json_mail['bodyPreview']
      end
    end

    def set_read_email mail
      uri      = URI("https://graph.microsoft.com/v1.0/users/#{ENV['EMAIL_USER_ID']}/messages/#{mail.id}")
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.patch uri, { 'isRead' => 'true' }.to_json, request_headers_patch
      end

      raise Net::HTTPError.new 'Invalid request', response.body unless response.kind_of? Net::HTTPSuccess
    end

    def token
      RedisClient.mgraph_token || new_token
    end

    def new_token
      response = request_new_token
      token    = parse_token_from_request response

      raise Net::HTTPError.new 'Invalid request', response.body unless token

      token
    rescue Net::HTTPError => e
      @retry ||= 4

      retry if (@retry -= 1).positive?

      raise e
    end

    def request_new_token
      uri           = URI("https://login.microsoftonline.com/#{ENV['EMAIL_TENANT_ID']}/oauth2/v2.0/token")
      token_request = Net::HTTP::Post.new uri, request_headers

      token_request.set_form_data grant_type: 'client_credentials', scope: 'https://graph.microsoft.com/.default'
      token_request.basic_auth *ENV['EMAIL_CLIENT_ID'], ENV['EMAIL_CLIENT_SECRET']

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request token_request
      end
    end

    def parse_token_from_request response
      if response.code == '200'
        token, expires_in = *JSON.parse(response.body).values_at('access_token', 'expires_in')

        RedisClient.assign_mgraph_token token, expires_in

        token
      end
    end

    def request_headers_patch
      {
        'Authorization' => "Bearer #{token}",
        'Content-Type'  => 'application/json'
      }
    end

    def authorized_request_headers
      request_headers.merge(
        'Authorization' => "Bearer #{token}"
      )
    end

    def request_headers
      {
        'Host'         => 'login.microsoftonline.com',
        'Content-Type' => 'application/x-www-form-urlencoded'
      }
    end
end
