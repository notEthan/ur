require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :default => :test

require 'gig'

ignore_files = %w(
  .github/**/*
  .gitignore
  Gemfile
  Rakefile.rb
  test/**/*
).map { |glob| Dir.glob(glob, File::FNM_DOTMATCH) }.inject([], &:|)

Gig.make_task(gemspec_filename: 'ur.gemspec', ignore_files: ignore_files)
