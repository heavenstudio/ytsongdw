require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

require 'open-uri'
require_relative 'lib/simple_logger'
require_relative 'lib/counter'
require_relative 'lib/file_settings'
require_relative 'lib/downloader'
require_relative 'lib/playlist_downloader'
require_relative 'lib/song_downloader'
require_relative 'lib/youtube_song_downloader'
