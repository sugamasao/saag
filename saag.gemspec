# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{saag}
  s.version = "0.3.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["sugamasao"]
  s.date = %q{2009-08-09}
  s.default_executable = ["saag"]
  s.description = %q{SAss Automatic monitor and Generate css file.}
  s.email = %q{sugamasao@gmail.com}
  s.executables = ["saag"]
  s.extra_rdoc_files = [
    "ChangeLog",
     "README.rdoc",
     "TODO"
  ]
  s.files = [
    "ChangeLog",
     "README.rdoc",
     "VERSION",
     "bin/saag",
     "lib/saag.rb"
  ]
  s.homepage = %q{http://github.com/sugamasao/saag}
  s.rdoc_options = ["--title", "saag documentation", "--charset", "utf-8", "--opname", "index.html", "--line-numbers", "--main", "README.rdoc", "--inline-source", "--exclude", "^(examples|extras)/"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.6")
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{SAss Automatic monitor and Generate css file.}
  s.test_files = [
    "spec/saag_spec.rb",
     "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<haml>, [">= 0"])
    else
      s.add_dependency(%q<haml>, [">= 0"])
    end
  else
    s.add_dependency(%q<haml>, [">= 0"])
  end
end
