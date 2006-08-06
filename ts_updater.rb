#!/usr/bin/env ruby -w

require 'rubygems'
require 'optparse'
require 'ostruct'
require 'extensions/all'
require 'rio'
require 'rexml/document'

class Message
  attr_accessor :source, :translation, :comment
  attr_accessor :type
  
  def initialize(root)
    @source = root.elements["source"].get_text
    @translation = root.elements["translation"].get_text
    @comment = root.elements["comment"]
    @comment = @comment.get_text if @comment
    @type = root.elements["translation"].attributes["type"]
  end
  
  def to_s
    "    <message>\n" +
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

  def initialize(root)
    @contexts = Array.new

    root.elements.each("context") do |context|
      @contexts << Context.new(context)
    end
  end

  def to_s
    "<!DOCTYPE TS><TS>\n" +
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
    
    opts = OptionParser.new do |opts|
      opts.banner += " <ts-file>"
      
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
    doc = REXML::Document.new(File.new(@options.files.first))
    ts = TS.new(doc.elements[1])

    rio(@options.output) < ts.to_s
  end
end

worker = Worker.parse(ARGV)
worker.go
