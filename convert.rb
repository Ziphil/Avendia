# coding: utf-8


require 'pp'
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

  def initialize(path, language)
    @path = path
    @language = language
    @latest = false
    @header_string = ""
    @navigation_string = ""
    @main_string = ""
    @title = ""
    @description = ""
  end

  def convert
    source = File.read(@path)
    element = Document.new(source, {:raw => :all}).root
    convert_element(element)
  end

  def convert_element(element)
    case element.name
    when "page"
      deepness = WholeZiphilConverter.deepness(@path, @language)
      virtual_deepness = (@path =~ /index\.zpml$/) ? deepness - 1 : deepness
      name_tag = TagBuilder.new("div", "name")
      if virtual_deepness >= -1
        first_category = @path.split("/")[-deepness - 1]
        first_link_tag = TagBuilder.new("a", "name")
        first_link_tag["href"] = "../../" + first_category
        if virtual_deepness == -1
          first_link_tag << NAMES[:top][@language]
        else
          first_link_tag << NAMES[first_category.intern][@language]
        end
        name_tag << first_link_tag
      end
      if virtual_deepness >= 1
        second_category = @path.split("/")[-deepness]
        united_category = first_category + "_" + second_category
        second_link_tag = TagBuilder.new("a", "name")
        second_link_tag["href"] = "../" + second_category
        second_link_tag << NAMES[united_category.intern][@language]
        name_tag << second_link_tag
      end
      if virtual_deepness >= 2
        if element.attribute("link")
          converted_path = @path.match(/([0-9a-z\-]+)\.zpml/).to_a[1].to_s
          converted_path += (element.attribute("link").value == "c") ? ".cgi" : ".html"
          third_link_tag = TagBuilder.new("a", "name")
          third_link_tag["href"] = converted_path
        else
          third_link_tag = TagBuilder.new("span")
        end
        name_element = element.elements["name"]
        third_link_tag << convert_children(name_element)
        name_tag << third_link_tag
        @title = flatten_text(name_element.inner_text(true))
      end
      @navigation_string << name_tag
      @main_string << convert_children(element)
    when "name"
    when "ver"
      if element.text == "*" || element.text =~ LATEST_VERSION_REGEX
        version_tag = TagBuilder.new("div", "version")
        @latest = true
      else
        version_tag = TagBuilder.new("div", "version-caution")
      end
      version_tag << convert_children(element)
      @navigation_string << version_tag
    when "import-script"
      script_tag = TagBuilder.new("script")
      script_tag["src"] = self.url_prefix + "file/script/" + element.attribute("src").to_s
      @header_string << script_tag
      @header_string << "\n"
    when "base"
      base_tag = TagBuilder.new("base")
      base_tag["href"] = element.attribute("href").to_s
      @header_string << base_tag
      @header_string << "\n"
    when "pb"
      tag = TagBuilder.new("div", "index-container")
      tag << convert_children(element)
    when "hb"
      tag = TagBuilder.new("div", "index-header")
      tag << convert_children(element)
    when "ab", "abo", "aba", "abd"
      case element.name
      when "ab"
        tag = TagBuilder.new("a", "index")
      when "abo"
        tag = TagBuilder.new("a", "old-index")
      when "aba"
        tag = TagBuilder.new("a", "ancient-index")
      when "abd"
        tag = TagBuilder.new("div", "disabled-index")
      end
      element.attributes.each_attribute do |attribute|
        if attribute.name == "date"
          date_tag = TagBuilder.new("span", "date")
          if element.attribute("date").value =~ /^\d+$/
            hairia_tag = TagBuilder.new("span", "hairia")
            hairia_tag << element.attribute("date").to_s
            date_tag << hairia_tag
          else
            date_tag << element.attribute("date").to_s
          end
          tag << date_tag
        else
          tag[attribute.name] = attribute.to_s
        end
      end
      content_tag = TagBuilder.new("span", "content")
      content_tag << convert_children(element)
      tag << content_tag
    when "h1", "h2"
      tag = TagBuilder.new(element.name)
      element.attributes.each_attribute do |attribute|
        if attribute.name == "number"
          number_tag = TagBuilder.new("span", "number")
          number_tag << element.attribute("number").to_s
          tag["id"] = element.attribute("number").to_s
          tag << number_tag
        else
          tag[attribute.name] = attribute.to_s
        end
      end
      tag << convert_children(element)
    when "p"
      tag = TagBuilder.new("p")
      tag << convert_children(element)
      if element.attribute("par")
        additional_tag = TagBuilder.new("span", "paragraph")
        additional_tag << element.attribute("par").to_s
        tag.insert_first(additional_tag)
      end
      if element.attribute("name")
        additional_tag = TagBuilder.new("span", "name")
        additional_tag << element.attribute("name").to_s
        tag.insert_first(additional_tag)
      end
      @description << flatten_text(element.inner_text(true))
    when "img"
      tag = TagBuilder.new("img", nil, false)
      tag["alt"] = ""
      element.attributes.each_attribute do |attribute|
        tag[attribute.name] = attribute.to_s
      end
      tag << convert_children(element)
    when "a"
      tag = pass_element(element)
    when "an"
      tag = TagBuilder.new("a", "normal")
      element.attributes.each_attribute do |attribute|
        tag[attribute.name] = attribute.to_s
      end
      tag << convert_children(element)
    when "ol", "ul"
      tag = pass_element(element)
    when "xl"
      tag = TagBuilder.new("ul", "conlang")
      tag << convert_children(element) do |inner_element|
        case inner_element.name
        when "li"
          inner_tag = TagBuilder.new("li")
          inner_tag << convert_children(inner_element) do |profound_element|
            case profound_element.name
            when "sh"
              profound_tag = TagBuilder.new
              profound_tag << convert_children(profound_element)
            when "ja"
              profound_tag = TagBuilder.new("ul")
              profound_item_tag = TagBuilder.new("li")
              profound_item_tag << convert_children(profound_element)
              profound_tag << profound_item_tag
            end
            next profound_tag
          end
        end
        next inner_tag
      end
    when "el"
      tag = TagBuilder.new("table", "list")
      tag << convert_children(element) do |inner_element|
        case inner_element.name
        when "li"
          inner_tag = TagBuilder.new("tr")
          inner_tag << convert_children(inner_element) do |profound_element|
            case profound_element.name
            when "et", "ed"
              profound_tag = TagBuilder.new("td")
              profound_tag << convert_children(profound_element)
            end
            next profound_tag
          end
        end
        next inner_tag
      end
    when "trans"
      tag = TagBuilder.new("table", "translation")
      tag << convert_children(element) do |inner_element|
        case inner_element.name
        when "li"
          inner_tag = TagBuilder.new("tr")
          inner_tag << convert_children(inner_element) do |profound_element|
            case profound_element.name
            when "ja", "sh"
              profound_tag = TagBuilder.new("td")
              profound_tag << convert_children(profound_element)
            end
            next profound_tag
          end
        end
        next inner_tag
      end
    when "section-table"
      tag = TagBuilder.new("ul", "section-table")
      section_item_tag = TagBuilder.new("li")
      subsection_tag = TagBuilder.new("ul")
      element.each_xpath("/page/*[name() = 'h1' or name() = 'h2']") do |inner_element|
        case inner_element.name
        when "h1"
          unless section_item_tag.content.empty?
            section_item_tag << subsection_tag unless subsection_tag.content.empty?
            tag << section_item_tag
          end
          section_item_tag = TagBuilder.new("li")
          subsection_tag = TagBuilder.new("ul")
          section_item_tag << convert_text(inner_element.get_text.to_s)
        when "h2"
          subsection_item_tag = TagBuilder.new("li")
          if inner_element.attribute("number")
            number_tag = TagBuilder.new("span", "number")
            link_tag = TagBuilder.new("a")
            number_tag << inner_element.attribute("number").to_s
            link_tag["href"] = "#" + inner_element.attribute("number").to_s
            link_tag << convert_text(inner_element.get_text.to_s.gsub(/\{(.+?)\}/){"\[#{$1}\]"})
            subsection_item_tag << number_tag
            subsection_item_tag << link_tag
          else
            subsection_item_tag << convert_text(inner_element.get_text.to_s)
          end
          subsection_tag << subsection_item_tag
        end
      end
      section_item_tag << subsection_tag unless subsection_tag.content.empty?
      tag << section_item_tag
    when "li"
      tag = pass_element(element)
    when "table"
      tag = pass_element(element)
    when "tr", "th", "td"
      tag = pass_element(element)
    when "thl"
      tag = TagBuilder.new("th", "left")
      tag << convert_children(element)
    when "form"
      tag = pass_element(element)
    when "input"
      tag = pass_element(element, false)
    when "textarea"
      tag = pass_element(element)
    when "error"
      tag = TagBuilder.new("div", "error")
      tag << convert_children(element) do |inner_element|
        case inner_element.name
        when "code"
          inner_tag = TagBuilder.new("div", "error-code")
          inner_tag << convert_children(inner_element)
        when "message"
          inner_tag = TagBuilder.new("div", "message")
          inner_tag << convert_children(inner_element)
        end
        next inner_tag
      end
    when "pdf"
      tag = TagBuilder.new("object", "pdf")
      tag["data"] = element.attribute("src").to_s + "#view=FitH&amp;statusbar=0&amp;toolbar=0&amp;navpanes=0&amp;messages=0"
      tag["type"] = "application/pdf"
    when "slide"
      tag = TagBuilder.new("div", "slide")
      script_tag = TagBuilder.new("script", "speakerdeck-embed")
      script_tag["async"] = "async"
      script_tag["data-id"] = element.attribute("id").to_s
      script_tag["data-ratio"] = "1.33333333333333"
      script_tag["src"] = "//speakerdeck.com/assets/embed.js"
      tag << script_tag
    when "pre", "samp"
      case element.name
      when "pre"
        tag = TagBuilder.new("table", "code")
      when "samp"
        tag = TagBuilder.new("table", "sample")
      end
      text = element.get_text.to_s.gsub(/\A\s*?\n/, "")
      indent_size = text.match(/\A(\s*?)\S/)[1].length
      text = text.rstrip.deindent
      tag << "\n"
      text.each_line do |line|
        row_tag = TagBuilder.new("tr")
        code_tag = TagBuilder.new("td")
        code_tag << line.chomp
        row_tag << code_tag
        tag << " " * indent_size
        tag << row_tag
        tag << "\n"
      end
      tag << " " * (indent_size - 2)
    when "c", "m"
      case element.name
      when "c"
        tag = TagBuilder.new("span", "code")
      when "m"
        tag = TagBuilder.new("span", "monospace")
      end
      element.children.each do |inner_element|
        case inner_element
        when Element
          tag << convert_element(inner_element)
        when Text
          tag << inner_element.to_s
        end
      end
    when "special"
      tag = pass_element(element)
    when "sup", "sub"
      tag = pass_element(element)
    when "h"
      tag = TagBuilder.new("span", "hairia")
      tag << convert_children(element)
    when "k"
      tag = TagBuilder.new("span", "japanese")
      tag << convert_children(element)
    when "i"
      tag = pass_element(element)
    when "fl"
      tag = TagBuilder.new("span", "foreign")
      tag << convert_children(element)
    when "small"
      tag = TagBuilder.new("span", "small")
      tag << convert_children(element)
    when "br"
      tag = pass_element(element, false)
    end
    return tag
  end

  def pass_element(element, close = true)
    tag = TagBuilder.new(element.name, nil, close)
    element.attributes.each_attribute do |attribute|
      tag[attribute.name] = attribute.to_s
    end
    tag << convert_children(element)
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

  def convert_children(element, &block)
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
          tag = convert_element(inner_element)
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

  def save
    convert
    File.open(@path.gsub("_source", "").gsub(".zpml", ".html"), "w") do |file|
      output = ORIGINAL_DATA.gsub(/#\{(.*?)\}\n?/){eval($1)}.gsub(/\r/, "")
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
      converter = ZiphilConverter.new(path, language)
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