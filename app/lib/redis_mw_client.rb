# frozen_string_literal: true

module RedisMwClient
  module_function

  DEFAULT_DB = 2

  def client db = DEFAULT_DB
    @client ||= {}

    @client[db] ||= RedisClient.new(
      host: REDIS_HOST,
      port: REDIS_PORT,
      db:   db
    )
  end

  def method_missing m, *args, &block
    client.send m, *args, &block
  end

  def paypal_token
    client.call 'GET', 'paypal_token'
  end

  def assign_paypal_token token, expire_in
    client.setex 'paypal_token', expire_in, token
  end

  def mgraph_token
    client.call 'GET', 'mgraph_token'
  end

  def assign_mgraph_token token, expire_in
    client.call 'SETEX', 'mgraph_token', expire_in, token
  end

  def license_plan_change_url subscription_id
    client.call 'GET', "plan_change_url_for_#{subscription_id}"
  end

  def assign_license_plan_change_url subscription_id, url
    client.call 'SET', "plan_change_url_for_#{subscription_id}", url
  end

  def clean_license_plan_change_url subscription_id
    client.call 'DEL', "plan_change_url_for_#{subscription_id}"
  end
end
