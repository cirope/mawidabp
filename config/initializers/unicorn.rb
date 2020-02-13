class Unicorn::HttpServer
  def kill_worker signal, wpid
    Process.kill :INT, wpid
  rescue Errno::ESRCH
    worker = WORKERS.delete(wpid) and worker.close rescue nil
  end
end
