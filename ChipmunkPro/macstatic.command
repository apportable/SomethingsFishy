#! /usr/bin/ruby

Dir.chdir(File.dirname($0))

PROJECT = "ChipmunkPro.xcodeproj"
SDK = "macosx10.9"
VERBOSE = true

require 'Tempfile'
BUILD_LOG = Tempfile.new("ChipmunkPro-")
BUILD_LOG_PATH = BUILD_LOG.path

def log(string)
	puts string
	open(BUILD_LOG_PATH, 'a'){|f| f.puts string}
end

def system(command)
	log "> #{command}"
	
	result = Kernel.system(VERBOSE ? "#{command} | tee -a #{BUILD_LOG_PATH}" : "#{command} >> #{BUILD_LOG_PATH}")
	
	if !result
		log "Command failed: #{command}"
		log "Build errors encountered. Aborting build script"
		log "Check the build log for more information: #{BUILD_LOG_PATH}"
		raise
	end
end

def build(target, configuration, trial)
	command = "xcodebuild -project #{PROJECT} -sdk #{SDK} -configuration #{configuration} -arch x86_64 -target #{target}"
	system command
	
	return "build/#{configuration}/lib#{target}.a"
end

def build_lib(target, copy_list, trial=false)
	build_lib(target, copy_list, false) if trial
	
	if(trial)
		debug_lib = build(target, "Debug-Trial", trial)
		release_lib = build(target, "Release-Trial", trial)
	else
		debug_lib = build(target, "Debug", trial)
		release_lib = build(target, "Release", trial)
	end
	
	dirname = "#{target}-#{trial ? "Mac-Trial" : "Mac"}"
	
	system "rm -rf #{dirname}"
	system "mkdir #{dirname}"
	
	system "cp #{debug_lib} #{dirname}/lib#{target}-Debug-Mac.a"
	system "cp #{release_lib} #{dirname}/lib#{target}-Mac.a"
	
	copy_list.each{|src| system "cp -r #{src} #{dirname}"}
end

build_lib("ChipmunkPro", [
	"Chipmunk/objectivec/include/ObjectiveChipmunk",
	"AutoGeometry/*.h",
	"HastySpace/*.h",
	"Chipmunk/include/chipmunk",
], true)

BUILD_LOG.delete
