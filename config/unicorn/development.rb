worker_processes 1
listen Rack::Server.new.options[:Port]
timeout 1800
