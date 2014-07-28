$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name          = "fluent-plugin-out_rawtcp"
  s.version       = `cat VERSION`
  s.authors       = ["lxfontes"]
  s.email         = ["lxfontes+rawtcp@gmail.com"]
  s.description   = %q{Raw tcp output plugin for Fluentd}
  s.summary       = %q{output plugin for fluentd}
  s.homepage      = "https://github.com/lxfontes/fluent-plugin-out_rawtcp"
  s.license       = 'MIT'

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_runtime_dependency "fluentd"

  s.add_development_dependency "rake"
  s.add_development_dependency "webmock"
end
