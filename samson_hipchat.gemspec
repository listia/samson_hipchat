Gem::Specification.new "samson_hipchat", "0.0.0" do |s|
  s.summary = "Samson hipchat integration"
  s.authors = ["Vinh Nguyen"]
  s.email = "vinh@listia.com"
  s.add_runtime_dependency "hipchat", "~> 1.5"
  s.files = `git ls-files`.split("\n")
end
