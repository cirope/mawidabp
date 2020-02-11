# frozen_string_literal: true

module RedisClient
  module_function

  DEFAULT_DB = 2

  def client db = DEFAULT_DB
    @client ||= {}

    @client[db] ||= Redis.new(
      host: REDIS_HOST,
      port: REDIS_PORT,
      db:   db
    )
  end

  def method_missing m, *args, &block
    client.send m, *args, &block
  end

  def paypal_token
    client.get 'paypal_token'
  end

  def assign_paypal_token token, expire_in
    client.setex 'paypal_token', expire_in, token
  end

  def license_plan_change_url subscription_id
    client.get "plan_change_url_for_#{subscription_id}"
  end

  def assign_license_plan_change_url subscription_id, url
    client.set "plan_change_url_for_#{subscription_id}", url
  end

  def clean_license_plan_change_url subscription_id
    client.del "plan_change_url_for_#{subscription_id}"
  end
end
