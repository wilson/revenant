# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{revenant}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.7")
  s.authors = ["Wilson Bilkovich"]
  s.date = %q{2010-05-25}
  s.email = %q{wilson@supremetyrant.com}
  s.files = %w[
    lib/revenant.rb
    lib/revenant/task.rb
    lib/revenant/manager.rb
    lib/plugins/daemon.rb
    lib/revenant/pid.rb
    lib/locks/mysql.rb
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/wilson/revenant}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Distributed daemons that just will not die.}

  s.specification_version = 2
end
