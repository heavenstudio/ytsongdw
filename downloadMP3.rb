#!/usr/bin/ruby

require 'nokogiri'
require 'youtube-dl.rb'
require 'open-uri'

$directory = "Music/";
filename=""
def download(url, name)
	location = $directory+name+'.mp3'
	# Download options
	options = {
	  format: 'bestaudio',
	  audio_format: "mp3",
	  output: location
	}
	YoutubeDL.download url, options
	puts "DONE (see the folder "+$directory+")"
end

def findTitle()

end

def parseURL(url)
	if(url.include? '&')
		url = url.slice(0, url.index('&'))
	end
	return url
end

def parseTitle(title)
	if(title.include? '-')
		title = title.slice(0, title.rindex('-'))
	end
	return title
end

def launchDownload(origURL, compteur, totalDownloads)
	url = parseURL(origURL)
	if(url.length<=1)
		return
	end
   	file = open(url)
	doc = Nokogiri::HTML(file)
	# Encoding options
	encoding_options = {
	    :invalid           => :replace,  # Replace invalid byte sequences
	    :undef             => :replace,  # Replace anything not defined in ASCII
	    :replace           => '',        # Use a blank for those replacements
	    :universal_newline => true       # Always break lines with \n
	  }
	title = doc.at_css('title').text.encode(Encoding.find('ASCII'), encoding_options) # Delete non ASCII chars 
	title = parseTitle(title)
	puts compteur.to_s+"/"+totalDownloads.to_s+"- "+title
	download(url, title)
end


# MAIN

if(ARGV.length != 1 || ARGV[0]=='-h' || ARGV[0]=='--help')
	puts "You  should pass one parameter: The URL link or The file containing all youtube songs URL to download"
	puts
	puts "Example1: ./downloadMP3.rb test.txt"
	puts "Example2: ./downloadMP3.rb https://www.youtube.com/watch?v=bM7SZ5SBzyY"
	puts
	exit 0
end

if(ARGV[0].include?('.txt'))
	filename = ARGV[0]
elsif (ARGV[0].include?('://'))
	filename = ""
else
	filename = ARGV[0]
end


if(filename!="")
	file=File.open(filename,"r")
	total_lines = file.readlines.size
	File.foreach(filename).with_index do |line, line_number|
	   	launchDownload(line, line_number+1, total_lines)
	end
	puts "FINISH"
else
	launchDownload(ARGV[0], 1, 1)
end

# END
