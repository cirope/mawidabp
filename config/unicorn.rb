# See http://unicorn.bogomips.org/Unicorn/Configurator.html for complete
# documentation.
#
# Use at least one worker per core if you're on a dedicated server,
# more will usually help for _short_ waits on databases/caches.
worker_processes 2

# Load rails into the master before forking workers for super-fast
# worker spawn times
preload_app true

app_path = File.expand_path('../..', __FILE__)

working_directory ENV['APP_HOME'] || app_path

if ENV['RAILS_LOG_TO_STDOUT']
  logger Logger.new($stdout)
else
  # By default, the Unicorn logger will write to stderr.
  # Additionally, ome applications/frameworks log to stderr or stdout,
  # so prevent them from going to /dev/null when daemonized here:
  stderr_path "#{app_path}/log/unicorn.stderr.log"
  stdout_path "#{app_path}/log/unicorn.stdout.log"
end

listen ENV['PORT'] || '/run/unicorn/unicorn.sock'

# nuke workers after 360 seconds
timeout 360

pid '/tmp/unicorn.pid'

GC.respond_to?(:copy_on_write_friendly=) and
  GC.copy_on_write_friendly = true

# Enable this flag to have unicorn test client connections by writing the
# beginning of the HTTP headers before calling the application.  This
# prevents calling the application for connections that have disconnected
# while queued.  This is only guaranteed to detect clients on the same
# host unicorn runs on, and unlikely to detect disconnects even on a
# fast LAN.
check_client_connection false

before_fork do |server, worker|
  # the following is highly recomended for Rails + "preload_app true"
  # as there's no need for the master process to hold a connection
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!

  # The following is only recommended for memory/DB-constrained
  # installations.  It is not needed if your system can house
  # twice as many worker_processes as you have configured.
  #
  # # This allows a new master process to incrementally
  # # phase out the old master process with SIGTTOU to avoid a
  # # thundering herd (especially in the "preload_app false" case)
  # # when doing a transparent upgrade.  The last worker spawned
  # # will then kill off the old master process with a SIGQUIT.
  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end

  # Throttle the master from forking too quickly by sleeping.  Due
  # to the implementation of standard Unix signal handlers, this
  # helps (but does not completely) prevent identical, repeated signals
  # from being lost when the receiving process is busy.
  sleep 1
end

after_fork do |server, worker|
  # the following is *required* for Rails + "preload_app true",
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection

  trap :INT do
    puts Thread.current.backtrace

    Process.kill :KILL, $$
  end
end
