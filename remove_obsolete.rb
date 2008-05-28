#!/usr/bin/env ruby -wKU

raise "Specify .ts file name" if ARGV.length != 1
file_name = ARGV[0]

require 'qt_linguist'
require 'rubygems'
require 'rio'

ts = TS.new(file_name)
ts.remove_obsolete!
rio(?-) < ts.to_s
