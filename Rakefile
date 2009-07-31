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
    "--main", "README.rdoc",
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
    gemspec.extra_rdoc_files      = ["README.rdoc", "ChangeLog", "TODO"]
    gemspec.required_ruby_version = Gem::Requirement.new(">= 1.8.6")
    
    gemspec.files                 = [
      "bin/saag", 
      "lib/saag.rb",
      "README.rdoc",
      "ChangeLog", 
      "VERSION"
    ]

    gemspec.add_dependency('haml')
  end
  
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end


task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION.yml')
    config = YAML.load(File.read('VERSION.yml'))
    version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "atnd4r #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('ChangeLog')
  rdoc.rdoc_files.include('TODO')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.options = ["--charset", "utf-8", "--line-numbers"]
end

