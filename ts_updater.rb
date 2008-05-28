#!/usr/bin/env ruby -w
# Qt Linguist patcher by Michail Pishchagin

require 'qt_linguist'

require 'rubygems'
require 'optparse'
require 'ostruct'
require 'rio'
# require 'extensions/all'

class Worker
private
  def initialize(options)
    @options = options
  end

public
  def self.parse(args)
    options = OpenStruct.new
    options.output = ?-
    options.patch_with = nil
    
    opts = OptionParser.new do |opts|
      opts.banner += " <ts-file>"
      
      opts.on("-p", "--patch-with FILE",
              "Replace as much messages as possible from FILE") do |file|
        options.patch_with = file
      end

      opts.on("-o", "--output FILE",
              "File to write the output to") do |file|
        options.output = file
      end
      
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end
    
    options.files = opts.parse!(args)
    if args.empty?
      puts "*** Input file not specified! ***"
      opts.parse("-h")
    end
    
    if args.length > 1
      puts "*** Too many input files! ***"
      opts.parse("-h")
    end
    Worker.new(options)
  end
  
  def log(str)
    rio(:stderr).noautoclose < str
  end
  
  def logn(str)
    log(str + "\n")
  end
  
  def go
    ts = TS.new(@options.files.first)

    if @options.patch_with
      patch = TS.new(@options.patch_with)
      patch.contexts.each do |context|
        ts_context = ts.contexts.find { |c| c.name == context.name }
        next if ts_context.nil?
        
        context.messages.each do |message|
          ts_message = ts_context.messages.find { |c| c.source == message.source }
          next if ts_message.nil?
          
          ts_message.translation = message.translation if message.translation.not_nil?
          ts_message.numerusform = message.numerusform if message.numerusform.not_nil?
        end
      end
    end

    rio(@options.output) < ts.to_s
  end
end

worker = Worker.parse(ARGV)
worker.go
