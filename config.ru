require 'rubygems'
require 'bundler'
Bundler.require

require 'webapp'
require 'sass/plugin'
Sass::Plugin.options[:load_paths] = ['views/css']
run Sinatra::Application

