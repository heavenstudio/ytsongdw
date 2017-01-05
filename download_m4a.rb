#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'scrapifier'
require 'youtube-dl.rb'
require 'open-uri'
require 'nokogiri'
require 'memoist'

extend Memoist

DOWNLOAD_DIRECTORY = '~/Music/'.freeze
YOUTUBE_BASE_URL = 'youtube.com'.freeze
YOUTUBE_HTTPS_URL = "https://www.#{YOUTUBE_BASE_URL}".freeze
YOUTUBE_WATCH_URL = "#{YOUTUBE_HTTPS_URL}/watch?v=".freeze
YOUTUBE_SEARCH_URL = "#{YOUTUBE_HTTPS_URL}/results?search_query=".freeze
MAXIMUM_NUMBER_OF_TRIES = 3

def download_directory
  if ARGV[1] && ARGV[1] != ''
    ARGV[1]
  else
    DOWNLOAD_DIRECTORY
  end
end

def download(url, name, subfolder = nil, number_of_tries = 1)
  return puts 'MAXIMUM NUMBER OF TRIES EXCEEDED' if number_of_tries > MAXIMUM_NUMBER_OF_TRIES
  location = download_directory + subfolder.to_s + sanitize_folder_name(name) + '.m4a'
  download_options = {
    format: 'm4a',
    output: location
  }
  puts "DOWNLOADING #{url}/#{name}"
  YoutubeDL.download url, download_options
rescue
  puts "COULDN'T DOWNLOAD #{url}/#{name} TRY ##{number_of_tries}"
  download(url, name, subfolder, number_of_tries + 1)
end

def sanitize_folder_name(folder_name)
  return '' if folder_name.nil? || folder_name == ''
  folder_name.strip.tr('/', '|')
end

def parse_url(input = nil)
  url = input.include?('youtube') ? input.strip : find_youtube_video(input)
  url = url.slice(0, url.index('&')) if url.include? '&'
  url
end

def find_youtube_video(name)
  search_url = YOUTUBE_SEARCH_URL + URI.encode(name)
  results = open(search_url).read

  return YOUTUBE_WATCH_URL + Regexp.last_match(1) if results =~ /watch\?v=([-\w_]+)/
  puts "DIDNT FIND ANY RESULTS FOR #{url}"
end

def parse_title(title)
  title = title.slice(0, title.rindex('-')) if title.include? '-'
  title.strip
end

def launch_download(url, n, total, playlist_n = nil, playlist_total = nil, subfolder = nil)
  return download_playlist(url, n, total) if playlist?(url)

  url = parse_url(url)
  title = parse_title(url.scrapify[:title])
  print_download_status(n, total, title, playlist_n, playlist_total)
  download(url, title, subfolder)
rescue OpenURI::HTTPError
  puts "COULDNT DOWNLOAD #{url}"
end

def download_playlist(url, n, total)
  playlist_total = playlist_urls(url).size
  subfolder = parse_title(url.scrapify[:title]) + '/'
  playlist_urls(url).each.with_index do |youtube_watch_url, i|
    launch_download parse_url(youtube_watch_url), n, total, i + 1, playlist_total, subfolder
  end
end

def print_download_status(n, total, title, playlist_n = nil, playlist_total = nil)
  if playlist_n.nil?
    puts "#{n}/#{total} - #{title}"
  else
    puts "#{n}/#{total} <#{playlist_n}/#{playlist_total}> - #{title}"
  end
end

def playlist?(url)
  url.include? YOUTUBE_BASE_URL + '/playlist?list='
end

def playlist_urls(url)
  html = Nokogiri::HTML(open(url).read)
  html.css('#pl-video-table tr td a')
      .select { |link| link.attr('href').include?('watch') }
      .map { |link| YOUTUBE_HTTPS_URL + link.attr('href') }
      .uniq
rescue
  puts "COULDN'T FETCH PLAYLIST VIDEO URLS"
  []
end

if ARGV.length.zero? || ARGV[0] == '-h' || ARGV[0] == '--help'
  puts 'You should pass one or two parameters: The song name/youtube url or the file'
  puts 'containing all youtube songs/urls to download and an optional folder to download'
  puts 'it to (defaults to ~/Music)'
  puts 'make sure youve run `bundle install` first to download dependencies and then one of:'
  puts 'Example1: bundle exec download_m4a.rb test.txt'
  puts 'Example2: bundle exec download_m4a.rb "https://www.youtube.com/watch?v=bM7SZ5SBzyY"'
  puts 'Example3: bundle exec download_m4a.rb "https://www.youtube.com/playlist?list=PL9B23A78D3D249A74"'
  puts 'Example4: bundle exec download_m4a.rb "Titanic Song"'
  puts
  exit 0
end

# memoizing methods that fetch data using http requests
memoize :playlist?, :playlist_urls, :find_youtube_video

if ARGV[0].include?('.txt')
  filename = ARGV[0]
  total_lines = File.open(filename).readlines.size
  File.open(filename).each_line.with_index do |line, line_number|
    launch_download(line, line_number + 1, total_lines)
  end
else
  launch_download(ARGV[0], 1, 1)
end
puts "DONE (see the folder '#{download_directory}')"
