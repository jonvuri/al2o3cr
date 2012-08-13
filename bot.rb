require 'cinch'
require 'open3'

def smush(text, length)
    array_len = (length / 3).ceil
    lines = text.lines.to_a.each { |l| l.chomp! }
    last = lines[-1]
    smushed = (lines.length < array_len ? lines.to_a[0..-2] : lines.to_a[0..(array_len-2)]).join(", ")
    if smushed.length < length
        return last, smushed
    else
        return last, smushed[0..length] + "..."
    end
end

# Scriptlet configuration
runner_script = 'result = eval(STDIN.read); puts "(#{result.class}) #{result.inspect}"'
resource_limits = { :rlimit_cpu => 1, :rlimit_nproc => 4, :rlimit_fsize => 50000 }

Cinch::Bot.new do
    configure do |c|
        c.server    =  "irc.freenode.net"
        c.nick      =  "al2o3cr"
        c.channels  =  ["#ruby"]
    end

    on :message, /^>>(.+)/ do |m, query|
        Open3.popen3("sudo", "-u", "jrajav", "ruby", "-e", runner_script, resource_limits) do |i, o, e, t|
            i.print query
            i.close
            stdout = o.read
            stderr = e.read
            if not stderr.empty?
                result, error = smush(stderr, 400)
                m.reply "#{error}, #{result}"
            else
                result, output = smush(stdout, 400)
                m.reply output.empty? ? result : "#{result}, Console: #{output}"
            end
        end
    end
end.start
