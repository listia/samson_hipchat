Gem::Specification.new "samson_hipchat", "0.1.7" do |s|
  s.summary = "Samson hipchat integration"
  s.authors = ["Vinh Nguyen"]
  s.email = "vinh@listia.com"
  s.add_runtime_dependency "hipchat", "~> 1.5"
  s.files =  Dir['{app,config,db,lib}/**/*.*'].reject { |f| f.match(%r{^(test|spec|features)/}) }
end
