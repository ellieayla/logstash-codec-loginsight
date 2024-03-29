Gem::Specification.new do |s|

  s.name            = 'logstash-codec-loginsight'
  s.version         = '0.1.50'
  s.licenses        = ['Apache-2.0']
  s.summary         = "This codec may be used to decode (via HTTP input) Ingestion API events from a Log Insight server."
  s.description     = "This gem is a Logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/logstash-plugin install logstash-codec-loginsight. This gem is not a stand-alone program."
  s.authors         = ["Ellie Ayla"]
  s.email           = 'support@verselogic.net'
  s.homepage        = "https://github.com/ellieayla/logstash-codec-loginsight"
  s.require_paths   = ["lib"]

  # Files
  s.files = Dir["lib/**/*","spec/**/*","*.gemspec","*.md","CONTRIBUTORS","Gemfile","LICENSE","NOTICE.TXT", "vendor/jar-dependencies/**/*.jar", "vendor/jar-dependencies/**/*.rb", "VERSION", "docs/**/*"]

  # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "codec" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core-plugin-api", ">= 1.60", "<= 2.99"

  s.add_development_dependency "logstash-devutils"
end
