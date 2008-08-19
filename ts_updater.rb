#!/usr/bin/env ruby -w
# Qt Linguist patcher by Michail Pishchagin

require 'qt_linguist'

require 'rubygems'
require 'optparse'
require 'ostruct'
require 'rio'
require 'extensions/all'

class String
  def simplify
    self.gsub(/\n/, ' ').gsub(/[\s]+/, ' ').lstrip.rstrip
  end
end

def compare_strings(str1, str2, do_simplify)
  return true if str1.nil? and str2.nil?
  return false if str1.nil?
  return false if str2.nil?

  if do_simplify
    return str1.simplify == str2.simplify
  else
    return str1 == str2
  end
end

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
    options.no_whitespace_comparison = false
    
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
      
      opts.on("-w", "--no-whitespace-comparison",
              "When comparing source / translation strings, don't compare whitespace") do
        options.no_whitespace_comparison = true
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
        ts_context = ts.contexts.find { |c| compare_strings(c.name.to_s, context.name.to_s, @options.no_whitespace_comparison) }
        next if ts_context.nil?
        
        context.messages.each do |message|
          ts_message = ts_context.messages.find { |c| compare_strings(c.source.to_s, message.source.to_s, @options.no_whitespace_comparison) }
          next if ts_message.nil?
          
          if @options.no_whitespace_comparison
            next if compare_strings(ts_message.translation.to_s, message.translation.to_s, true)
          end
          
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
