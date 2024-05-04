Gem::Specification.new do |s|
  s.name    = 'ruby_claim_evidence_api'
  s.version = '0.0.1'
  s.summary = 'Claim Evidence API so that Caseflow can utilize it'
  s.license = 'CC0' # This work is a work of the US Federal Government,
  #               This work is Public Domain in the USA, and CC0 Internationally

  s.authors = 'Caseflow'
  s.email   = 'vacaseflowops@va.gov'

  s.add_development_dependency 'aws-sdk', '~> 2.10'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rspec'

  s.add_dependency 'base64'
  s.add_dependency 'httpi'

  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'faraday'
  s.add_runtime_dependency 'faraday-multipart'
  s.add_runtime_dependency 'railties'
  s.add_runtime_dependency 'webmock'

  s.files = Dir['lib/**/*.rb']
  s.require_paths = ['lib']
end
