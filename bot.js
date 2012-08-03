var jerk = require('jerk');
var exec = require('child_process').exec;
var fs = require('fs');

var fileinc = 0;

var options =
	{ server: 'irc.freenode.net'
	, nick: 'al2o3cr'
	, channels: [ '#ruby' ]
	};

jerk( function( j ) {
	j.watch_for( options.nick + ': ping', function( message ) {
		message.say( message.user + ': pong' );
	});

	j.watch_for( options.nick + ': version', function( message ) {
		exec('ruby -v', function (err, stdout, stderr) {
			message.say(err !== null ? err : stdout);
		});
	});

	j.watch_for( /^>>\s*([^`]+)$/, function( message ) {
		var file;
		fileinc += 1;
		file = 'r' + fileinc + '.rb';
		fs.writeFileSync(file,'require \'sandrbox\'\nSandrbox.configure do |config| config.bad_constants << :ObjectSpace end\nresult = Sandrbox.perform([%`STDOUT = STDIN = $stdout = $stdin = nil; ' + message.match_data[1] + '`]).output[-1]\nputs "(" + result.class.inspect + ") " + result.inspect');
		exec('ruby ' + file, function (err, stdout, stderr) {
			var output;
			if (err === null) {
				output = stdout.split('\n');
				output = output[output.length - 2];
				if (output.length > 200) {
					message.say(message.user + ': Output too long, I PMed it to you');
					message.msg(output);
				} else {
					message.say(message.user + ': ' + output);
				}
			} else {
				message.msg('stdout: ' + stdout.substring(0, 500) + '\nstderr: ' + stderr.substring(0, 500));
				message.say(message.user + ': The Ruby interpreter exited with nonzero status. Hanmac is probably to blame.');
			}
			fs.unlink(file);
		});
	});

	j.watch_for( /^>>.*`.*/, function( message ) {
		message.say( message.user + ': I don\'t evaluate code with backticks for spiritual reasons' );
	});
}).connect( options );
