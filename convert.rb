﻿# coding: utf-8


require 'pp'
require 'fileutils'
require 'rexml/document'
include REXML

Kernel.load(File.dirname($0).encode("utf-8") + "/lbs/file/module/1.rb")
Encoding.default_external = "UTF-8"
$stdout.sync = true


class ZiphilConverter

  NAMES = {
    :title => {:ja => "人工言語シャレイア語", :en => "Sheleian Constructed Language"},
    :top => {:ja => "トップページ", :en => "Top"},
    :conlang => {:ja => "人工言語", :en => "Conlang"},
    :conlang_grammer => {:ja => "文法書", :en => "Grammar"},
    :conlang_course => {:ja => "入門書", :en => "Introduction"},
    :conlang_database => {:ja => "データベース", :en => "Database"},
    :conlang_culture => {:ja => "文化", :en => "Culture"},
    :conlang_translation => {:ja => "翻訳", :en => "Translations"},
    :conlang_theory => {:ja => "シャレイア語論", :en => "Studies"},
    :conlang_document => {:ja => "資料", :en => "Data"},
    :conlang_table => {:ja => "一覧表", :en => "Tables"},
    :application => {:ja => "自作ソフト", :en => "Softwares"},
    :application_download => {:ja => "ダウンロード", :en => "Download"},
    :application_web => {:ja => "Web アプリ", :en => "Web Application"},
    :language => {:ja => "自然言語", :en => "Language"},
    :language_french => {:ja => "フランス語", :en => "French"},
    :language_german => {:ja => "ドイツ語", :en => "German"},
    :language_russian => {:ja => "ロシア語", :en => "Russian"},
    :diary => {:ja => "日記", :en => "Diary"},
    :diary_conlang => {:ja => "人工言語", :en => "Conlang"},
    :diary_mathematics => {:ja => "数学", :en => "Mathematics"},
    :diary_application => {:ja => "プログラミング", :en => "Programming"},
    :diary_game => {:ja => "ゲーム制作", :en => "Game"},
    :other => {:ja => "その他", :en => "Others"},
    :other_mathematics => {:ja => "数学", :en => "Mathematics"},
    :other_other => {:ja => "その他", :en => "Others"},
    :error => {:ja => "エラー", :en => "Error"},
    :error_error => {:ja => "エラー", :en => "Error"}
  }
  LANGUAGE_NAMES = {:ja => "日本語", :en => "English"}
  DOMAINS = {:ja => "http://ziphil.com/", :en => "http://en.ziphil.com/"}
  LATEST_VERSION_REGEX = /(5\s*代\s*5\s*期|Version\s*5\.5)/
  ORIGINAL_DATA = DATA.read

  attr_reader :path
  attr_reader :language
  attr_reader :title
  attr_reader :description

  def initialize(source, path, language)
    @source = source
    @path = path
    @language = language
    @latest = false
    @header_string = ""
    @navigation_string = ""
    @main_string = ""
    @title = ""
    @description = ""
    @templates = {}
  end

  def convert
    element = Document.new(@source, {:raw => :all}).root
    convert_element(element, "")
  end

  def convert_element(element, scope)
    @templates.each do |(element_pattern, scope_pattern), block|
      if element_pattern === element.name && scope_pattern === scope
        return block.call(element)
      end
    end
    return ""
  end

  def pass_element(element, scope, close = true)
    tag = TagBuilder.new(element.name, nil, close)
    element.attributes.each_attribute do |attribute|
      tag[attribute.name] = attribute.to_s
    end
    tag << apply(element, scope)
    return tag
  end

  def convert_text(text, only_slash = false)
    result = ""
    text = text.clone
    text.gsub!("{{", "<<<CL>>>")
    text.gsub!("}}", "<<<CR>>>")
    text.gsub!("[[", "<<<BL>>>")
    text.gsub!("]]", "<<<BR>>>")
    text.gsub!("//", "<<<S>>>")
    text.gsub!("、", "、 ")
    text.gsub!("。", "。 ")
    text.gsub!("「", " 「")
    text.gsub!("」", "」 ")
    text.gsub!("『", " 『")
    text.gsub!("』", "』 ")
    text.gsub!("〈", " 〈")
    text.gsub!("〉", "〉 ")
    text.gsub!(/(、|。)\s+(」|』)/){$1 + $2}
    text.gsub!(/(」|』|〉)\s+(、|。|,|\.)/){$1 + $2}
    text.gsub!(/(\(|「|『)\s+(「|『)/){$1 + $2}
    text.gsub!(/(^|>)\s+(「|『)/){$1 + $2}
    text.split(/(\{.+?\}|\[.+?\]|\/.+?\/)/).each_with_index do |each_text, index|
      each_text.gsub!("<<<CL>>>", "{")
      each_text.gsub!("<<<CR>>>", "}")
      each_text.gsub!("<<<BL>>>", "[")
      each_text.gsub!("<<<BR>>>", "]")
      each_text.gsub!("<<<S>>>", "/")
      if index % 2 == 0
        result << each_text
      else
        url = "#{self.url_prefix}conlang/database/1.cgi"
        unless only_slash
          if match = each_text.match(/\A\{(.+?)\}\z/)
            link = @latest && @path =~ /conlang\/.+\/\d+(\-\w{2})?\.zpml/
            result << WordConverter.convert(convert_text(match[1], true), url, link)
          elsif match = each_text.match(/\A\[(.+?)\]\z/)
            result << WordConverter.convert(convert_text(match[1], true), url, false)
          elsif match = each_text.match(/\A\/(.+?)\/\z/)
            result << "<i>"
            result << convert_text(match[1])
            result << "</i>"
          end
        else
          if match = each_text.match(/\A\/(.+?)\/\z/)
            result << "<i>"
            result << convert_text(match[1])
            result << "</i>"
          else
            result << each_text
          end
        end
      end
    end
    return result
  end

  def flatten_text(text)
    text = text.clone
    text.gsub!("{{", "<<<CL>>>")
    text.gsub!("}}", "<<<CR>>>")
    text.gsub!("[[", "<<<BL>>>")
    text.gsub!("]]", "<<<BR>>>")
    text.gsub!("//", "<<<S>>>")
    text.gsub!("{", "")
    text.gsub!("}", "")
    text.gsub!("[", "")
    text.gsub!("]", "")
    text.gsub!("/", "")
    text.gsub!("\"", "&quot;")
    text.gsub!("<<<CL>>>", "{")
    text.gsub!("<<<CR>>>", "}")
    text.gsub!("<<<BL>>>", "[")
    text.gsub!("<<<BR>>>", "]")
    text.gsub!("<<<S>>>", "/")
    return text
  end

  def apply(element, scope, &block)
    result = ""
    element.children.each do |inner_element|
      case inner_element
      when Element
        if block
          tag = block.call(inner_element)
          if tag
            result << tag
          end
        else
          tag = convert_element(inner_element, scope)
          if tag
            result << tag
          end
        end
      when Text
        result << convert_text(inner_element.to_s)
      end
    end
    return result
  end

  def add(element_pattern, scope_pattern, &block)
    @templates.store([element_pattern, scope_pattern], block)
  end

  def save
    path = @path.gsub("_source", "").gsub(".zpml", ".html")
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, "w") do |file|
      output = ORIGINAL_DATA.gsub(/#\{(.*?)\}/){self.instance_eval($1)}.gsub(/\r/, "")
      file.print(output)
    end
  end

  def url_prefix
    return "../" * WholeZiphilConverter.deepness(@path, @language)
  end

  def foreign_language
    return (@language == :ja) ? :en : :ja
  end

  def main_type
    deepness = WholeZiphilConverter.deepness(@path, @language)
    return (deepness.between?(1, 2) && path =~ /index\.zpml/) ? "content-table" : "main"
  end

  def online_url
    root_path = WholeZiphilConverter::ROOT_PATHS[@language]
    domain = DOMAINS[@language]
    return @path.gsub(root_path + "/", domain).gsub(/\.zpml$/, ".html")
  end

end


class WholeZiphilConverter

  ROOT_PATHS = {
    :ja => File.dirname($0).encode("utf-8") + "/lbs_source",
    :en => File.dirname($0).encode("utf-8") + "/lbs-en_source"
  }

  def initialize(args)
    @args = args
  end

  def save
    paths = self.paths
    paths.each_with_index do |(path, language), index|
      before_time = Time.now
      source = File.read(path)
      converter = ZiphilConverter.new(source, path, language)
      converter.instance_eval(File.read(File.dirname($0) + "/template.rb"))
      converter.convert
      converter.save
      after_time = Time.now
      output = " "
      output << "%3d" % (index + 1)
      output << " : "
      output << "%4d" % ((after_time - before_time) * 1000)
      output << " ms  |  "
      output << "#{language} "
      path_array = path.gsub(ROOT_PATHS[language] + "/", "").split("/")
      path_array.map!{|s| (s =~ /\d/) ? "%3d" % s.to_i : s.gsub("index.zpml", "  *")[0..2]}
      output << path_array.join(" ")
      puts(output)
    end
    puts("----------------------------------")
    puts(" " * 24 + "#{"%3d" % paths.size} files")
  end

  def paths
    paths = []
    if @args.empty?
      ROOT_PATHS.each do |language, default|
        directories = []
        directories << default
        directories.each do |directory|
          entries = Dir.entries(directory)
          entries.each do |entry|
            if /\.zpml/ =~ entry
              paths << [directory + "/" + entry, language]
            end
            unless /\./ =~ entry
              directories << directory + "/" + entry
            end
          end
        end
      end
    else
      path = @args.map{|s| s.gsub("\\", "/").gsub("c:/", "C:/")}[0].encode("utf-8")
      language = ROOT_PATHS.find{|s, t| path.include?(t)}&.first
      if language
        paths << [path, language]
      end
    end
    paths.sort_by! do |path, language|
      path_array = path.gsub(ROOT_PATHS[language] + "/", "").gsub(".zpml", "").split("/")
      path_array.reject!{|s| s.include?("index")}
      path_array.map!{|s| (s.match(/^\d/)) ? s.to_i : s}
      next [path_array, language]
    end
    return paths
  end

  def self.deepness(path, language)
    path.split("/").size - ROOT_PATHS[language].count("/") - 2
  end

end


class TagBuilder

  attr_accessor :name
  attr_accessor :content

  def initialize(name = nil, clazz = nil, close = true)
    @name = name
    @attributes = (clazz) ? {"class" => clazz} : {}
    @content = ""
    @close = close
  end

  def [](key)
    return @attributes[key]
  end

  def []=(key, value)
    @attributes[key] = value
  end

  def <<(content)
    @content << content
  end

  def insert_first(content)
    @content.sub!(/(\A\s*)/m){$1 + content.to_str}
  end

  def to_s
    result = ""
    if @name
      result << "<"
      result << @name
      @attributes.each do |key, value|
        result << " #{key}=\"#{value}\""
      end
      result << ">"
      result << @content
      if @close
        result << "</"
        result << @name
        result << ">"
      end
    else
      result << @content
    end
    return result
  end

  def to_str
    return self.to_s
  end

end


class Element

  def inner_text(compress = false)
    text = XPath.match(self, ".//text()").map{|s| s.value}.join("")
    if compress
      text.gsub!(/\r/, "")
      text.gsub!(/\n\s*/, " ")
      text.gsub!(/\s+/, " ")
      text.strip!
    end
    return text
  end

  def each_xpath(*args, &block)
    if block
      XPath.each(self, *args) do |element|
        block.call(element)
      end
    else
      enumerator = Enumerator.new do |yielder|
        XPath.each(self, *args) do |element|
          yielder << element
        end
      end
      return enumerator
    end
  end

end


class String

  def indent(size)
    inside_code = false
    split_self = self.each_line.map do |line|
      if inside_code 
        if line =~ /^\s*<\/pre>/
          inside_code = false
        end
        next line
      else
        if line =~ /^\s*<pre>/
          inside_code = true
        end
        next " " * size + line
      end
    end
    return split_self.join
  end

  def deindent
    margin = self.scan(/^ +/).map(&:size).min
    return self.gsub(/^ {#{margin}}/, "")
  end

  def deindent!
    margin = self.scan(/^ +/).map(&:size).min
    self.gsub!(/^ {#{margin}}/, "")
  end

end


class Array

  def ===(other)
    return self.include?(other)
  end

end


converter = WholeZiphilConverter.new(ARGV)
converter.save


__END__
<!DOCTYPE html>

<html lang="#{self.language}">
  <head>
    <meta charset="UTF-8">
    <meta name="twitter:card" content="summary">
    <meta name="twitter:site" content="@Ziphil">
    <meta property="og:url" content="#{self.online_url}">
    <meta property="og:title" content="#{self.title}">
    <meta property="og:description" content="#{self.description}">
    <meta property="og:image" content="#{ZiphilConverter::DOMAINS[self.language]}material/logo/1.png">
#{@header_string.strip.indent(4)}
    <link rel="stylesheet" type="text/css" href="#{self.url_prefix}style/reset.css">
    <link rel="stylesheet" type="text/css" href="#{self.url_prefix}style/1.css">
    <title>Avendia 19 — #{NAMES[:title][self.language]}</title>
  </head>
  <body>

    <div class="header">
      <div class="title"><a href="#{self.url_prefix}">Avendia<sup>19</sup></a></div>
      <div class="language"><a href="#{DOMAINS[self.foreign_language]}">#{LANGUAGE_NAMES[self.foreign_language]}</a></div>
    </div>

    <ul class="menu">
      <li>
        <a href="#{self.url_prefix}conlang/">#{NAMES[:conlang][self.language]}</a>
        <ul>
          <li><a href="#{self.url_prefix}conlang/grammer/">#{NAMES[:conlang_grammer][self.language]}</a></li>
          <li><a href="#{self.url_prefix}conlang/course/">#{NAMES[:conlang_course][self.language]}</a></li>
          <li><a href="#{self.url_prefix}conlang/database/">#{NAMES[:conlang_database][self.language]}</a></li>
          <li><a href="#{self.url_prefix}conlang/culture/">#{NAMES[:conlang_culture][self.language]}</a></li>
          <li><a href="#{self.url_prefix}conlang/translation/">#{NAMES[:conlang_translation][self.language]}</a></li>
          <li><a href="#{self.url_prefix}conlang/theory/">#{NAMES[:conlang_theory][self.language]}</a></li>
          <li><a href="#{self.url_prefix}conlang/document/">#{NAMES[:conlang_document][self.language]}</a></li>
          <li><a href="#{self.url_prefix}conlang/table/">#{NAMES[:conlang_table][self.language]}</a></li>
        </ul>
      </li>
      <li>
        <a href="#{self.url_prefix}application/">#{NAMES[:application][self.language]}</a>
        <ul>
          <li><a href="#{self.url_prefix}application/download/">#{NAMES[:application_download][self.language]}</a></li>
          <li><a href="#{self.url_prefix}application/web/">#{NAMES[:application_web][self.language]}</a></li>
        </ul>
      </li>
      <li>
        <a href="#{self.url_prefix}language/">#{NAMES[:language][self.language]}</a>
        <ul>
          <li><a href="#{self.url_prefix}language/french/">#{NAMES[:language_french][self.language]}</a></li>
          <li><a href="#{self.url_prefix}language/german/">#{NAMES[:language_german][self.language]}</a></li>
          <li><a href="#{self.url_prefix}language/russian/">#{NAMES[:language_russian][self.language]}</a></li>  
        </ul>
      </li>
      <li>
        <a href="#{self.url_prefix}diary/">#{NAMES[:diary][self.language]}</a>
        <ul>
          <li><a href="#{self.url_prefix}diary/conlang/">#{NAMES[:diary_conlang][self.language]}</a></li>
          <li><a href="#{self.url_prefix}diary/mathematics/">#{NAMES[:diary_mathematics][self.language]}</a></li>
          <li><a href="#{self.url_prefix}diary/application/">#{NAMES[:diary_application][self.language]}</a></li>
          <li><a href="#{self.url_prefix}diary/game/">#{NAMES[:diary_game][self.language]}</a></li>
        </ul>
      </li>
      <li>
        <a href="#{self.url_prefix}other/">#{NAMES[:other][self.language]}</a>
        <ul>
          <li><a href="#{self.url_prefix}other/mathematics/">#{NAMES[:other_mathematics][self.language]}</a></li>
          <li><a href="#{self.url_prefix}other/other/">#{NAMES[:other_other][self.language]}</a></li>
        </ul>
      </li>
    </ul>

    <div class="navigation">
  #{@navigation_string.strip.indent(4)}
    </div>

    <div class="#{self.main_type}">
  #{@main_string.strip.indent(4)}
    </div>

    <div class="footer">
      <div class="icon">
        <a class="twitter" href="https://twitter.com/Ziphil" target="_blank"></a>
        <a class="youtube" href="https://www.youtube.com/channel/UCF2sTP1NGBVFr79aJiKprsg/" target="_blank"></a>
      </div>
      <div class="copyright">
        Copyright © 2009–#{Time.now.year} Ziphil, All rights reserved.
      </div>
      <div class="counter">
        <script src="http://counter1.fc2.com/counter.php?id=3102008"></script><noscript><img alt="counter" src="http://counter1.fc2.com/counter_img.php?id=3102008"></noscript> 
      </div>
    </div>

  </body>
</html>