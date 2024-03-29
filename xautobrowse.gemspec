Gem::Specification.new do |s|
  s.name = 'xautobrowse'
  s.version = '0.3.6'
  s.summary = "A poor man's web automation tool primarily for " + \
      "Firefox in an X windows system."
  s.authors = ['James Robertson']
  s.files = Dir['lib/xautobrowse.rb']
  s.add_runtime_dependency('xtabbedwindow', '~> 0.1', '>=0.1.4')
  s.add_runtime_dependency('nokorexi', '~> 0.7', '>=0.7.0')
  s.add_runtime_dependency('clipboard', '~> 1.3', '>=1.3.6')
  s.add_runtime_dependency('simplepubsub', '~> 1.3', '>=1.3.2')
  s.add_runtime_dependency('universal_dom_remote', '~> 0.1', '>=0.1.1')
  s.signing_key = '../privatekeys/xautobrowse.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'digital.robertson@gmail.com'
  s.homepage = 'https://github.com/jrobertson/xautobrowse'
  s.required_ruby_version = '>= 2.5.0'
end
