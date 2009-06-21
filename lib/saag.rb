# $Id$

require 'optparse'
require 'logger'
require 'pp'

class Saag
#  Version  = '0.1.0'
  SASS_EXT = '.sass'
  CSS_EXT  = '.css'

  def initialize(argv = [])
    # parse option
    @conf = {}
    @exit = false
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO # default Log Level

    begin
      OptionParser.new do |opt|
        opt.on('-i', '--input_path=VAL', 'input file path(directory or filename)') {|v| @conf[:in_path] = set_dir_path(v)}
        opt.on('-o', '--output_path=VAL', 'generated css file output path') {|v| @conf[:out_path] = set_dir_path(v)}
        opt.on('-r', '--render_opt=VAL', 'sass render option [nested or expanded or compact or compressed]' ){|v| @conf[:render_opt] = set_render_opt(v)}
        opt.on('-d', '--debug', 'log level to debug') {|v| @conf[:debug] = v}
      end.parse!(argv)
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
      @logger.error('invalid args...! looks for "-h" option')
      exit 1
    end

    @logger.info("sass file watching start... [app ver=#{Version}]")
    @logger.level = Logger::DEBUG if @conf[:debug]

    @logger.debug("args input_path  => #{@conf[:in_path]}")
    @logger.debug("args output_path => #{@conf[:out_path]}")
    @logger.debug("args render_opt  => #{@conf[:render_opt]}")

    set_default_conf()
    set_signal()

    @logger.info("watching directory => #{@conf[:in_path]}")
    @logger.info("output   directory => #{@conf[:out_path]}")
  end

  def run
    old_list = []
    # メインループ
    begin
      loop do 
        old_list = main_loop(old_list)
        break if @exit # SIGNAL を受けたりすると true
        sleep 1
      end
    rescue SystemCallError => e
      @logger.error("File I/O Error! [#{e.message}]")
    rescue => e
      @logger.error("FATLE Error! [#{e.message}]")
    end

    @logger.info("sass file watching exit...")
  end

  private

  def main_loop(old_list)
    new_list = get_file_list(@conf[:in_path])
    
    file_list = check_file_list(old_list, new_list)

    file_list.each do |sass_file|
      if sass_file[:change]
        @logger.info("change file found. => #{sass_file[:path]}")
        css_text = Sass::Engine.new(File.read(sass_file[:path]), {:style => @conf[:render_opt] }).render
        write_css_file(sass_file, css_text)
      end
    end

    return new_list
  end

  # 絶対パスにし、ディレクトリの場合は最後尾にスラッシュを付ける
  def set_dir_path(path)
    path =  File.expand_path(path)
    path = path + '/' if File.directory?(path)
    return path
  end

  def set_signal
    begin
      Signal.trap(:INT){
        @logger.debug("Signal Trapping [:INT]")
        @exit = true
      }
    rescue ArgumentError => e
      @logger.debug("Signal Setting Error[#{e.message}]")
    end

    begin
      Signal.trap(:TERM){
        @logger.debug("Signal Trapping [:TERM]")
        @exit = true
      }
    rescue ArgumentError => e
      @logger.debug("Signal Setting Error[#{e.message}]")
    end

    begin
      Signal.trap(:HUP){
        @logger.debug("Signal Trapping [:HUP]")
        @exit = true
      }
    rescue ArgumentError => e
      @logger.debug("Signal Setting Error[#{e.message}]")
    end

    begin
      Signal.trap(:BREAK){
        @logger.debug("Signal Trapping [:BREAK]")
        @exit = true
      }
    rescue ArgumentError => e
      @logger.debug("Signal Setting Error[#{e.message}]")
    end
  end

  def set_render_opt(input_opt)
    opt = ""
    case input_opt.downcase
    when 'nested'
      opt = :nested
    when 'expanded'
      opt = :expanded
    when 'compact'
      opt = :compact
    when 'compressed'
      opt = :compressed
    else
      opt = :nested
    end

    return opt
  end

  def set_default_conf()
    if @conf[:in_path].nil? or @conf[:in_path].empty?
      @conf[:in_path] = Dir.pwd + '/'
    end
    if @conf[:out_path].nil? or @conf[:out_path].empty?
      if File.directory?(@conf[:in_path])
        @conf[:out_path] = @conf[:in_path]
      else
        @conf[:out_path] =File.dirname( @conf[:in_path]) + '/'
      end
    end
    if @conf[:render_opt].nil? or @conf[:render_opt].empty?
      @conf[:render_opt] = :nested
    end
  end

  # ファイルのパスと時刻のリストを作成する
  def get_file_list(in_path)
    list = []
    if File.file?(in_path)
        list << create_file_data(in_path)
    else 
      list = Dir.glob("#{in_path}**/*#{SASS_EXT}").map do |m|
        if File.file?(m)
          create_file_data(m)
        end
      end
    end
    
    return list.compact
  end

  def create_file_data(path)
    # 入力パスと実ファイルのパスの差分を出す（この差分が出力ディレクトリの連結パスとなる）
    sub_path = ""
    @logger.debug("create_file_data@path    => [#{path}]")
    @logger.debug("create_file_data@in_path => [#{@conf[:in_path]}]")
    if path =~ /#{@conf[:in_path]}(.+)/
      sub_path = $1
    end
    data = {
      :path => path, 
      :sub_path => sub_path, 
      :time => File.mtime(path), 
      :change => true
    }
    @logger.debug("create_file_data@sub_path => #{sub_path}")
    return data
  end

  def check_file_list(old_list, new_list)
    return new_list if old_list.empty?

    new_list.each do |new|
      old_list.each do |old|
        if(new[:path] == old[:path])
          if(new[:time] > old[:time])
            new[:change] = true
          else
            new[:change] = false
          end
        end
      end
    end

    return new_list
  end

  def write_css_file(sass_file, css_text)
    @logger.debug("@conf[:out_path] = #{@conf[:out_path]}, sass_file[:sub_path] = #{sass_file[:sub_path]}")
    out_dir = ""
    if sass_file[:sub_path].empty?
      out_dir      = @conf[:out_path]
    else
      out_dir      = File.dirname(@conf[:out_path] + sass_file[:sub_path]) + '/'
    end
    filename     = out_dir + File.basename(sass_file[:path], SASS_EXT) + CSS_EXT
    @logger.debug("out_dir => #{out_dir}")

    # ディレクトリが無ければ作成する
    unless File.directory?(out_dir)
      FileUtils.mkdir_p(out_dir)
      @logger.info("create output directory => #{out_dir}")
    end
    
    File.open(filename, 'w') do |f|
      f.puts(css_text)
    end
    @logger.info("generate css file => #{filename}")
  end
end

