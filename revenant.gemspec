# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{revenant}
  s.version = "0.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.7")
  s.authors = ["Wilson Bilkovich"]
  s.date = %q{2014-04-20}
  s.email = %q{wilson@supremetyrant.com}
  s.files = Dir['{LICENSE,README}'] + Dir['lib/**/*.rb'] + Dir['example/*']
  s.has_rdoc = false
  s.homepage = %q{http://github.com/wilson/revenant}
  s.require_paths = ["lib"]
  s.summary = %q{Distributed daemons that just will not die.}
  s.description = "A framework for building reliable distributed workers."
end
