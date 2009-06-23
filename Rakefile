# $Id$

###############################
# 1. rake gemspec # --> generate gemspec.
# 2. rake build   # --> create gems file.
# 3. gem install ./pkg/saag-#{VARSION}.gem
###############################

AUTHOR = "sugamasao"
EMAIL = "sugamasao@gmail.com"
DESCRIPTION = "SAss Automatic monitor and Generate css file."
SUMMARY = DESCRIPTION
BIN_FILES = %w(saag)
NAME = "saag"
RDOC_OPTS = ['--title', "#{NAME} documentation",
    "--charset", "utf-8",
    "--opname", "index.html",
    "--line-numbers",
    "--main", "README",
    "--inline-source",
]

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name                  = NAME
    gemspec.executables           = BIN_FILES
    gemspec.default_executable    = BIN_FILES
    gemspec.description           = DESCRIPTION
    gemspec.summary               = DESCRIPTION
    gemspec.email                 = EMAIL
    gemspec.rdoc_options          = RDOC_OPTS + ['--exclude', '^(examples|extras)/']
    gemspec.has_rdoc              = true
    gemspec.homepage              = "http://github.com/sugamasao/#{NAME}"
    gemspec.authors               = AUTHOR
    gemspec.extra_rdoc_files      = ["README", "ChangeLog", "TODO"]
    gemspec.required_ruby_version = Gem::Requirement.new(">= 1.8.6")
    
    gemspec.files                 = [
      "bin/saag", 
      "lib/saag.rb",
      "README",
      "ChangeLog"
    ]

    gemspec.add_dependency('haml')
  end
  
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

