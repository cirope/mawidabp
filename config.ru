# This file is used by Rack-based servers to start the application.

# Unicorn self-process killer
require 'unicorn/worker_killer'

# Max requests per worker
use Unicorn::WorkerKiller::MaxRequests, 3072, 4096

# Max memory size (RSS) per worker
use Unicorn::WorkerKiller::Oom, (128 * (1024 ** 2)), (384 * (1024 ** 2))

require_relative 'config/environment'

run Rails.application
Rails.application.load_server
