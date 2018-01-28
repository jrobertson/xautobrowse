Gem::Specification.new do |s|
  s.name = 'xautobrowse'
  s.version = '0.1.2'
  s.summary = "A poor man's web automation tool primarily for " + \
      "Firefox in an X windows system."
  s.authors = ['James Robertson']
  s.files = Dir['lib/xautobrowse.rb']
  s.add_runtime_dependency('xdo', '~> 0.0', '>=0.0.4')  
  s.add_runtime_dependency('ruby-wmctrl', '~> 0.0', '>=0.0.6')
  s.add_runtime_dependency('nokorexi', '~> 0.3', '>=0.3.2')
  s.add_runtime_dependency('clipboard', '~> 1.1', '>=1.1.1')
  s.signing_key = '../privatekeys/xautobrowse.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/xautobrowse'
  s.required_ruby_version = '>= 2.5.0'
end
