#shell = Shell.new("ruby -e 'sleep 3 and puts Time.now'")
#shell.run
#p shell

class Shell
  attr_accessor :cmd, :pid, :output, :exitstatus, :thread
  def initialize(cmd)
    @cmd = cmd
    queue = Queue.new
    @thread = Thread.new(queue) {|q|
      pipe = IO.popen(cmd + " 2>&1")
      q.push(pipe)
      q.push(pipe.pid)
      self.pid = pipe.pid
      begin
        self.output = pipe.readlines
        pipe.close
        self.exitstatus = $?.exitstatus
      rescue => e
        q.push e
      end
    }
    queue.clear
  end
  def run
    thread.join
  end
end

