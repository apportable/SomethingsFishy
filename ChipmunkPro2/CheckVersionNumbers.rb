# There's got to be a better way to synchronize all of these... but whatever.

PATTERN = /[567]\.\d\.\d/

VERS = ARGV[0]
raise "didn't specify current version" unless VERS

def count_matches(str)
	match = PATTERN.match(str)
	if match
		return count_matches(match.post_match) + (match[0] == VERS ? 0 : 1)
	else
		return 0
	end
end

def ignore_line(line)
	return true if line.start_with?("./CheckVersionNumbers.rb")
	return true if line.start_with?("./Chipmunk/VERSION.txt")
	return true if count_matches(line) == 0
	return true if line.include?("@deprecated")
end

IO.readlines("|grep -rnIP -e '#{PATTERN}' .").each{|line|
	puts line unless ignore_line(line)
}