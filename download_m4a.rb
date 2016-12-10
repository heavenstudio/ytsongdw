#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'nokogiri'
require 'youtube-dl.rb'
require 'open-uri'

DOWNLOAD_DIRECTORY = '~/Music/'.freeze

def download(url, name)
  location = DOWNLOAD_DIRECTORY + name.strip.tr('/', '|') + '.m4a'
  # Download options
  options = {
    format: 'm4a',
    output: location
  }
  puts "DOWNLOADING #{url}/#{name}"
  YoutubeDL.download url, options
  puts "DONE (see the folder '#{DOWNLOAD_DIRECTORY}')"
end

def parse_url(url = nil)
  if url.include?('youtube.com')
    url = url.strip
  else
    search_url = "https://www.youtube.com/results?search_query=#{URI.encode(url)}"
    results = open(search_url).read
    if results =~ /watch\?v=([-\w_]+)/
      url = "https://www.youtube.com/watch?v=#{Regexp.last_match(1)}"
    else
      puts "DIDNT FIND ANY RESULTS FOR #{url}"
      url = nil
    end
  end

  url = url.slice(0, url.index('&')) if url.include? '&'
  url
end

def parse_title(title)
  title = title.slice(0, title.rindex('-')) if title.include? '-'
  title
end

def launch_download(url, compteur, totalDownloads)
  file = open(url)
  doc = Nokogiri::HTML(file)
  # Encoding options
  encoding_options = {
    invalid: :replace, # Replace invalid byte sequences
    undef: :replace, # Replace anything not defined in ASCII
    replace: '', # Use a blank for those replacements
    universal_newline: true # Always break lines with \n
  }
  title = doc.at_css('title').text.encode(Encoding.find('ASCII'), encoding_options) # Delete non ASCII chars
  title = parse_title(title)
  puts compteur.to_s + '/' + totalDownloads.to_s + '- ' + title
  download(url, title)
rescue OpenURI::HTTPError
  puts "COULDNT DOWNLOAD #{url}"
end

if ARGV.length != 1 || ARGV[0] == '-h' || ARGV[0] == '--help'
  puts 'You  should pass one parameter: The URL link or The file containing all youtube songs URL to download'
  puts 'make sure youve run `bundle install` first to download dependencies and then one of:'
  puts 'Example1: bundle exec download_m4a.rb test.txt'
  puts 'Example2: bundle exec download_m4a.rb https://www.youtube.com/watch?v=bM7SZ5SBzyY'
  puts 'Example3: bundle exec download_m4a.rb "Titanic Song"'
  puts
  exit 0
end

if ARGV[0].include?('.txt')
  filename = ARGV[0]
  file = File.open(filename)
  total_lines = File.open(filename).readlines.size
  File.open(filename).each_line.with_index do |line, line_number|
    launch_download(parse_url(line), line_number + 1, total_lines)
  end
  puts 'FINISHED'
else
  launch_download(parse_url(ARGV[0]), 1, 1)
end
