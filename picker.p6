use fatal;
constant FILE = 'servers.txt';

my %server;
try {
	my $server = slurp FILE;
	%server = $server.lines.map(*.split("=", 2).hash);
	CATCH {
		default {
			write-server-file('');
			say "Created default server list file";
		}
	}
}

say "Welcome to ServerPick6r.";

help unless %server;
list-servers;

while $_ = lc prompt "Command? " {
	when "?" | "help" {
		help
	}
	when "list" | "ls" {
		list-servers
	}
	when /:s ^p[lay]? (\w+)$/ {
		play(~$0)
	}
	when /:s ^[p[lay]? ]?(\d+)$/ {
		play(+$0)
	}
	when /:s ^[remove|rm] (\d+)$/ {
		remove(+$0);
	}
	when /:s ^[remove|rm] (\w+)$/ {
		remove(~$0);
	}
	when /:s ^[add|'+'] (\w+) (\S+)$/ {
		add(~$0, ~$1)
	}
}

sub help {
	say q:to/HELP/;
	Available commands:
	 - <number>: Launches server n° <number>
	 - p, play <server>: Launches server with name or ID <number>
	 - ls, list: Lists the available servers
	 - add, + <name> <url>: Add a server with the logon server <url> for the name <name>
	 - help, ?: Displays this message
	HELP
}

sub list-servers {
	say "Available servers" if %server;
	my $i;
	for %server.keys.sort -> $name {
		say "[{++$i}] $name (%server{$name})"
	}
}

multi sub play(Int $server) {
	if $server < 1 || $server > +%server {
		say "Wrong server ID";
	} else {
		play(%server.keys.sort[$server - 1]);
	}
}

multi sub play(Str $name) {
	if %server{$name}:exists {
		launch($name);
	} else {
		my @fuzzy-matches = %server.keys.grep(*.starts-with($name));
		given @fuzzy-matches {
			when * > 1 {
				say "Ambiguous matches:";
				.say for @fuzzy-matches.map({" - $_"});
			}
			when 1 {
				my $name = @fuzzy-matches[0];
				say "Found fuzzy match $name";
				launch($name);
			}
			default {
				say "Invalid server";
			}
		}
	}
}

multi sub remove(Int $server) {
	if $server < 1 || $server > +%server {
		say "Wrong server ID";
		list-servers;
	} else {
		my $name = %server.keys.sort[$server - 1];
		say "Removing server $name (%server{$name})";
		%server{$name}:delete;
		write-server-hash;
	}
}

sub launch(Str $name) {
	say "Playing on $name (%server{$name})";
	my $realmlist = "set realmlist %server{$name}";
	for dir('Data') {
		my $rl-file = "$_/realmlist.wtf";
		next unless .IO.d && $rl-file.IO ~~ :e & :f;
		spurt $rl-file, $realmlist;
	}
	run "Wow.exe";
	exit;
}

multi sub remove(Str $server) {
	say $server;
}


sub add(Str $name, Str $url) {
	if %server{$name}:exists {
		say "A server with this name already exists";
		return;
	}
	if $name ~~ /'='/ {
		say "Invalid server name";
		return;
	}
	say "Adding server <$name> for url <$url>";
	%server{lc $name} = lc $url;
	write-server-hash;
}

sub write-server-hash {
	my $server = %server.kv.map({"$^k=$^v"}).join("\n");
	write-server-file $server;
}

sub write-server-file(Str $contents) {
	spurt FILE, $contents;
	CATCH {
		default {
			say "Unable to write server file";
			exit;
		}
	}
}
