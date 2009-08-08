require File.expand_path(File.dirname(__FILE__) + '/spec_helper')


class Saag
  # private methods to public
  public :main_loop, :set_dir_path, :set_signal, :set_render_opt, :set_default_conf, :get_file_list, :create_file_data, :write_css_file, :check_file_list, :set_default_time
end

describe Saag, "test" do
end
