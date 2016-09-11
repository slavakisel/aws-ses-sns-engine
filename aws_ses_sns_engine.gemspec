$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "aws_ses_sns_engine/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "aws_ses_sns_engine"
  s.version     = AwsSesSnsEngine::VERSION
  s.authors     = ["Ole Morten Amundsen"]
  s.email       = ["ole@paladinsoftware.com"]
  s.homepage    = "http://github.com/paladinsoftware/aws-ses-sns-enginge"
  s.summary     = "AwsSesSnsEngine simplifies creating verified sender emails and subscribing to bounce and complaints through SNS"
  s.description = "AwsSesSnsEngine simplifies creating verified sender emails and subscribing to bounce and complaints through SNS. At courtesy of Paladin Software"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.5"

  s.add_development_dependency "sqlite3"
end
