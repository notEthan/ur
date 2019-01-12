require 'ur' unless Object.const_defined?(:Ur)

class Ur
  class Processing
    include SubUr

    def began_at
      began_at_s ? Time.parse(began_at_s) : nil
    end
    def began_at=(time)
      self.began_at_s = time ? time.utc.iso8601(6) : nil
    end

    attr_accessor :began_at_ns

    def begin!
      self.began_at ||= Time.now
      self.began_at_ns ||= Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
    end
    def finish!
      return if duration
      if began_at_ns
        now_ns = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
        self.duration = (now_ns - began_at_ns) * 1e-9
      elsif began_at
        now = Time.now
        self.duration = (now.to_f - began_at.to_f)
      end
    end
  end
end
