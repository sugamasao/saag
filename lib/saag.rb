# $Id$

require 'optparse'
require 'logger'
require 'pp'

#
# Sass 補助ツール、saag クラスです
#
class Saag
  SASS_EXT = '.sass'
  CSS_EXT  = '.css'

  #== saag Constructor
  # 引数の解析、及び初期値の設定を行います
  #
  #=== 引数
  # 引数となる配列
  #
  #=== 例外
  # 特になし
  #
  def initialize(argv = [])
    # クラス共通の値
    @app_name = self.class
    begin
      @version  = File.read("#{File.dirname(__FILE__)}/../VERSION").chomp
    rescue => e
      @version = "0.0.0"
    end

    # 引数オプション格納用
    @conf = {}

    # シグナル受信用フラグ（シグナルを受けたら true にして終了する）
    @exit = false

    # Loger の設定
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO # default Log Level

    begin
      OptionParser.new do |opt|
        opt.on('-i', '--input_path=VAL',  'input file path(directory or filename)') {|v| @conf[:in_path] = set_dir_path(v)}
        opt.on('-o', '--output_path=VAL', 'generated css file output path') {|v| @conf[:out_path] = set_dir_path(v)}
        opt.on('-r', '--render_opt=VAL',  'sass render option [nested or expanded or compact or compressed]' ){|v| @conf[:render_opt] = set_render_opt(v)}
        opt.on('-v', '--version',         'show version' ) { puts "#{@app_name} #{@version}"; exit 1 }
        opt.on('-d', '--debug',           'log level to debug') {|v| @conf[:debug] = v}
      end.parse!(argv)
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
      @logger.error('invalid args...! looks for "-h" option')
      exit 1
    end

    @logger.info("sass file watching start... [#{@app_name} = #{@version}]")
    @logger.level = Logger::DEBUG if @conf[:debug]

    @logger.debug("args input_path  => #{@conf[:in_path]}")
    @logger.debug("args output_path => #{@conf[:out_path]}")
    @logger.debug("args render_opt  => #{@conf[:render_opt]}")

    set_default_conf()
    set_signal()

    @logger.info("watching directory => #{@conf[:in_path]}")
    @logger.info("output   directory => #{@conf[:out_path]}")
  end

  #== saag#run
  # saag によるファイル監視を実行します
  #
  #=== 引数
  # なし
  #
  #=== 戻り値
  # なし
  #
  #=== 例外
  # なし
  #
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

  ############################
  # private methods
  ############################
  private

  #== saag#main_loop
  # saag の監視処理のメイン処理です。
  # このメソッドを繰り返し呼ぶ事で監視処理を実施しています。
  #
  #=== 引数
  # _old_list_::  Array オブジェクト 前回の main_loop メソッドで取得したファイルリストの一覧。
  #
  #=== 戻り値
  # Array:: main_loop内で取得したファイルリストの配列。
  #
  #=== 例外
  # なし
  # 
  def main_loop(old_list)
    return nil if @exit # SIGNAL を受けていたら処理を抜ける
    new_list = get_file_list(@conf[:in_path])
    
    return nil if @exit # SIGNAL を受けていたら処理を抜ける
    file_list = check_file_list(old_list, new_list)

    return nil if @exit # SIGNAL を受けていたら処理を抜ける
    file_list.each do |sass_file|
      if sass_file[:change]
        @logger.info("change file found. => #{sass_file[:path]}")
        css_text = Sass::Engine.new(File.read(sass_file[:path]), {:style => @conf[:render_opt] }).render
        write_css_file(sass_file, css_text)
      end
    end

    return new_list
  end

  #== saag#set_dir_path
  # 絶対パスにし、ディレクトリの場合は最後尾にスラッシュを付ける
  #
  #=== 引数
  # _path_:: ファイルパスの記載された String オブジェクト
  #
  #=== 戻り値
  # String:: ディレクトリであれば末尾に '/' を付加した、絶対パスのファイル名
  #
  #=== 例外
  # なし
  #
  def set_dir_path(path)
    path =  File.expand_path(path)
    path = path + '/' if File.directory?(path)
    return path
  end

  #== saag#set_signal
  # シグナルハンドラの設定
  # シグナルを受けると即死するのではなく、キリの良いところで終了するよう、
  # 終了フラグを true にするだけの処理を行う。
  #
  #=== 引数
  # なし
  #
  #=== 戻り値
  # なし
  #
  #=== 例外
  # なし
  # 
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

  #== saag#set_render_opt
  # sass 実行時のオプション設定用メソッド
  # オプションで値が渡されていれば その値を、そうでなければでフォルト値のnestedを使う。
  #
  #=== 引数
  # _input_opt_:: 引数の -r で入力された文字列
  #
  #=== 戻り値
  # Symbol:: 入力された文字列に対応した Symbol
  #
  #=== 例外
  # なし
  #
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

  #== saag#set_default_conf
  # sass 実行時のオプション設定用メソッド。
  # 省略時の入力パスと出力パスを設定する。
  # ディレクトリの場合は '/' を付加する。
  #
  #=== 引数
  # なし
  #
  #=== 戻り値
  # なし
  #
  #=== 例外
  # なし
  # 
  def set_default_conf()
    unless @conf[:in_path]
      @conf[:in_path] = Dir.pwd + '/'
    end
    unless @conf[:out_path]
      if File.directory?(@conf[:in_path])
        @conf[:out_path] = @conf[:in_path]
      else
        @conf[:out_path] =File.dirname( @conf[:in_path]) + '/'
      end
    end
    unless @conf[:render_opt]
      @conf[:render_opt] = :nested
    end
  end

  #== saag#get_file_list
  # ファイルのパスと時刻のリストを作成する
  #
  #=== 引数
  # _in_path_:: 引数の -i で入力されたパス
  #
  #=== 戻り値
  # Array:: 時刻とパスを保持したファイルリスト。
  #
  #=== 例外
  # なし
  #
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

  #== saag#create_file_data
  # ファイルパスと時刻等を保持した HASH を生成する。
  # 生成する HASH の内容は以下の通り
  # * :path => ファイルの絶対パス
  # * :sub_path => 入力時に指定されたディレクトリ以降からのファイルパス
  # * :time => 対象ファイルの mtime
  # * :change => 前回との変更があったか？を現すフラグ（この時点では全て true）
  #
  #=== 引数
  # _path_:: ファイルパス
  #
  #=== 戻り値
  # Hash:: 時刻とパス等を保持した Hash データ。
  #
  #=== 例外
  # なし
  # 
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

  #== saag#check_file_list
  # 前回走査したファイルリストと、今回走査したファイルリストにおいて、
  # ファイルの更新や追加があったリストの :change を true にし、そうでなければ false にする。
  #
  #=== 引数
  # _old_list_:: 前回のループで取得したファイルリストの Array
  # _new_list_:: 今回のループで取得したファイルリストの Array
  #
  #=== 戻り値
  # Array:: change フラグの更新が終わった new_list
  #
  #=== 例外
  # なし
  def check_file_list(old_list, new_list)
    return new_list if old_list.empty?

    new_list.each do |new|
      old_list.each do |old|
        if(new[:path] == old[:path]) # 前回と今回で同じファイルがあれば、時刻の比較を行う
          if(new[:time] > old[:time]) # 時刻が更新されていれば true
            new[:change] = true
          else
            new[:change] = false
          end
        end
      end
    end

    return new_list
  end

  #== saag#write_css_file
  # 変換された CSS ファイルを出力する
  #
  #=== 引数
  # _sass_file:: 変換対象のファイルの Hash
  # _css_text_:: 変換された CSS テキストの String
  #
  #=== 戻り値
  # なし
  #
  #=== 例外
  # SystemCallError:: ファイル出力時の例外時に出力
  # 
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

