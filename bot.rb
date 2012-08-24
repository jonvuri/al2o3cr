require 'cinch'
require 'open3'
require 'timeout'

def smush(text, length)
    array_len = (length / 3).ceil
    half_len = (length / 2).floor
    lines = text.lines.to_a.each { |l| l.chomp! }
    last = lines[-1]
    smushed = (lines.length < array_len ? lines.to_a[0..-2] : lines.to_a[0..(array_len-2)]).join(", ")
    if (last.length + smushed.length) > length
        if last.length > half_len
            last = last[0..half_len] + "..."
        end
        if smushed.length > half_len
            smushed = smushed[0..half_len] + "..."
        end
    end
    return last, smushed
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
        Open3.popen3("timeout", "2", "sudo", "-u", "jrajav", "ruby", "-E", "binary:binary", "-e", runner_script, resource_limits) do |i, o, e, t|
            i.print query
            i.close
            stdout = o.read
            stderr = e.read
            if not stderr.empty?
                result, error = smush(stderr, 500)
                m.reply "#{error}, #{result}"
            else
                result, output = smush(stdout, 500)
                m.reply output.empty? ? result : "#{result}, Console: #{output}"
            end
        end
    end

    on :message, /^!(panic|zomg|dammit|apocalypse|reset)/ do |m, query|
        panic = ["AAAAAAAH", "PANIC", "HOLY HELL", "AAAAUUUUGH", "SWEET ZOMBIE JESUS", "NOOOOOOO", "SAVE YOURSELF"]
        phew = ["All better", "Phew!", "Crisis averted", "Still alive~"]
        m.reply panic.sample
        Process.spawn "pkill -u jrajav"
        m.reply phew.sample
    end
end.start
