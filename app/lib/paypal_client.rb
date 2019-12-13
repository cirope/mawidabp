# frozen_string_literal: true

module PaypalClient
  module_function

  require 'net/http'

  STATUS = {
    approved:  'APPROVED',
    active:    'ACTIVE',
    pending:   'APPROVAL_PENDING',
    suspended: 'SUSPENDED',
    expired:   'EXPIRED',
    cancelled: 'CANCELLED'
  }.freeze

  PAYPAL_DOMAIN = ENV['PAYPAL_DOMAIN']

  def get_subscription reference_id
    result = request_get "/v1/billing/subscriptions/#{reference_id}"

    parse_subscription(result) || { status: :no_results }
  end

  def authorize_change_of_plan reference_id, plan_id
    result = request_post "/v1/billing/subscriptions/#{reference_id}/revise", plan_id: plan_id

    parse_plan_changed(result) || { status: :error, response: :general_problem }
  end

  def parse_subscription response
    case response['status']
    when STATUS[:approved], STATUS[:active]
      {
        status:     :paid,
        paid_until: Time.parse(response['billing_info']['next_billing_time']),
        plan_id:    response['plan_id']
      }
    when STATUS[:pending]
      { status: :in_process }
    end
  end

  def parse_plan_changed response
    if response['links']
      link = response['links'].find { |l| l['rel'] == 'approve' }['href']

      { status: :success, response: link }
    elsif (issue = response['details']&.first&.fetch 'issue', nil)
      { status: :error, response: issue.downcase }
    end
  end

  def request_get path
    uri      = URI(PAYPAL_DOMAIN + path)
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.get uri, authorized_request_headers
    end

    JSON.parse response.body
  end

  def request_post path, params
    uri      = URI(PAYPAL_DOMAIN + path)
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.post uri, params.to_json, authorized_request_headers
    end

    JSON.parse response.body
  end

  def token
    RedisClient.paypal_token || new_token
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
    uri           = URI("#{PAYPAL_DOMAIN}/v1/oauth2/token")
    token_request = Net::HTTP::Post.new uri, request_headers

    token_request.set_form_data grant_type: 'client_credentials'
    token_request.basic_auth *Rails.application.credentials.paypal.values_at(:client_id, :client_secret)

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request token_request
    end
  end

  def parse_token_from_request response
    if response.code == '200'
      token, expires_in = *JSON.parse(response.body).values_at('access_token', 'expires_in')

      RedisClient.assign_paypal_token token, expires_in

      token
    end
  end

  def request_headers
    {
      'Accept'          => 'application/json',
      'Accept-Language' => 'en_US',
      'Content-Type'    => 'application/json'
    }
  end

  def authorized_request_headers
    request_headers.merge(
      'Authorization' => "Bearer #{token}"
    )
  end
end
