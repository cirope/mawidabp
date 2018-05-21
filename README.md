# MawidaBP

Audit assistant web application

[![Build Status](https://travis-ci.org/cirope/mawidabp.svg?branch=master)](https://travis-ci.org/cirope/mawidabp)

## Generate cipher keys
```ruby
require 'openssl'
require 'base64'

cipher = OpenSSL::Cipher::AES256.new(:CBC)
cipher.encrypt
key = Base64.encode64(cipher.random_key)
iv = Base64.encode64(cipher.random_iv)
```
