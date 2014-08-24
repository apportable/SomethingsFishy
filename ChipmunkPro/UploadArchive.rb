VERS = ARGV[0]
raise("No version number!") unless VERS

def system(command)
	puts command
	Kernel.system(command)
end

SSH_CONNECT = "|ssh slembcke.net 'cd chipmunk-physics.net/release; sh'"

def system_remote(command)
	puts "#{SSH_CONNECT} > #{command}"
	open(SSH_CONNECT, 'w+'){|ssh| ssh.puts command}
end

system("rsync /tmp/Chipmunk-#{VERS}.tgz slembcke.net:chipmunk-physics.net/release/Chipmunk-7.x/")
system("rsync /tmp/ChipmunkPro-Trial-#{VERS}.tgz slembcke.net:chipmunk-physics.net/release/Chipmunk-7.x/")

system("rsync /tmp/ChipmunkPro-#{VERS}.tgz slembcke.net:chipmunk-physics.net/release/chipmunkPro/")

DOC = "Chipmunk-6.x/Chipmunk-#{VERS}-Docs"
REF = "Chipmunk-6.x/Chipmunk-#{VERS}-API-Reference"

system("rsync -r /tmp/Chipmunk-#{VERS}/doc/ slembcke.net:chipmunk-physics.net/release/#{DOC}")
system("rsync -r /tmp/ChipmunkPro-TMP/API-Reference/ slembcke.net:chipmunk-physics.net/release/#{REF}")

system_remote("rm ChipmunkLatest.tgz; ln -s Chipmunk-7.x/Chipmunk-#{VERS}.tgz ChipmunkLatest.tgz")

DOC_LINK = "ChipmunkLatest-Docs"
REF_LINK = "ChipmunkLatest-API-Reference"

system_remote("rm #{DOC_LINK}; ln -s #{DOC} #{DOC_LINK}")
system_remote("rm #{REF_LINK}; ln -s #{REF} #{REF_LINK}")
