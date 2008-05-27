#!/usr/bin/env ruby -w
# Qt Linguist patcher by Michail Pishchagin

require 'rubygems'
require 'optparse'
require 'ostruct'
require 'extensions/all'
require 'rio'
require 'rexml/document'

class Message
  attr_accessor :source, :translation, :comment, :location_file, :location_line
  attr_accessor :type
  
  def initialize(root)
    @source = root.elements["source"].get_text
    @translation = root.elements["translation"].get_text
    @comment = root.elements["comment"]
    @comment = @comment.get_text if @comment
    location = root.elements["location"]
    @location_file = location.attributes["filename"] if location
    @location_line = location.attributes["line"] if location
    @type = root.elements["translation"].attributes["type"]
  end
  
  def to_s
    "    <message>\n" +
    (@location_file.nil? ? '' : "        <location filename=\"#@location_file\" line=\"#@location_line\"/>\n") +
    "        <source>#@source</source>\n" +
    (@comment.nil? ? '' : "        <comment>#@comment</comment>\n") +
    "        <translation#{@type ? " type=\"#@type\"" : ''}>#@translation</translation>\n" +
    "    </message>"
  end
end

class Context
  attr_accessor :name, :messages

  def initialize(root)
    @name = root.elements["name"].text
    @messages = Array.new

    root.elements.each("message") do |message|
      @messages << Message.new(message)
    end
  end
  
  def to_s
    "<context>\n" +
    "    <name>#@name</name>\n" +
    @messages.map { |e| e.to_s }.join("\n") + "\n" +
    "</context>"
  end
end

class TS
  attr_accessor :contexts

  def initialize(file_name)
    doc = REXML::Document.new(File.new(file_name))
    root = doc.elements[1]
    @contexts = Array.new

    root.elements.each("context") do |context|
      @contexts << Context.new(context)
    end
  end

  def to_s
    "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" +
    "<!DOCTYPE TS><TS version=\"1.1\" language=\"ru_RU\">\n" +
    @contexts.map { |e| e.to_s }.join("\n") + "\n" +
    "</TS>\n"
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
        end
      end
    end

    rio(@options.output) < ts.to_s
  end
end

worker = Worker.parse(ARGV)
worker.go
