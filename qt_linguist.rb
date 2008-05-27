# Parser of Qt Linguist .ts files by Michail Pishchagin

require 'rexml/document'

class Message
  attr_accessor :source, :translation, :comment, :location_file, :location_line
  attr_accessor :type, :encoding, :numerus
  attr_accessor :numerusform
  
  def initialize(root)
    @source = root.elements["source"].get_text
    @translation = root.elements["translation"].get_text
    @comment = root.elements["comment"]
    @comment = @comment.get_text if @comment
    location = root.elements["location"]
    @location_file = location.attributes["filename"] if location
    @location_line = location.attributes["line"] if location
    @type = root.elements["translation"].attributes["type"]
    @encoding = root.attributes["encoding"]
    @numerus = root.attributes["numerus"]
    @numerusform = Array.new
    root.elements["translation"].elements.each("numerusform") do |numerusform|
      @numerusform << numerusform.get_text
    end
  end
  
  def to_s
    "    <message#{@encoding ? " encoding=\"#@encoding\"" : ''}#{@numerus ? " numerus=\"#@numerus\"" : ''}>\n" +
    (@location_file.nil? ? '' : "        <location filename=\"#@location_file\" line=\"#@location_line\"/>\n") +
    "        <source>#@source</source>\n" +
    (@comment.nil? ? '' : "        <comment>#@comment</comment>\n") +
    (@numerusform.empty? ?
    "        <translation#{@type ? " type=\"#@type\"" : ''}>#@translation</translation>\n" :
    "        <translation>\n" +
    @numerusform.map { |e| "            <numerusform>#{e}</numerusform>" }.join("\n") + "\n" +
    "        </translation>\n") +
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
    "<!DOCTYPE TS><TS version=\"1.1\" language=\"ru\">\n" +
    "<defaultcodec></defaultcodec>\n" +
    @contexts.map { |e| e.to_s }.join("\n") + "\n" +
    "</TS>\n"
  end
end
