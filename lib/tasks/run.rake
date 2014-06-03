# Our custom Rakefile tasks for loading the data
require 'loaders/code_review_parser'
require 'loaders/code_review_loader'
require 'loaders/cve_loader'
require 'loaders/git_log_loader'
require 'consolidators/filepath_consolidator'
require 'consolidators/developer_consolidator'
require 'verify/verify_runner'
require 'stats'

task :run => [:environment, "run:env", "run:prod_check", "db:reset", "run:parse", "run:load", "run:optimize", "run:consolidate","run:verify", "run:analyze"] do
  puts "Run task completed. Current time is #{Time.now}"
end

namespace :run do
  
  desc "Load data into tables"
  task :load => :environment do
    Benchmark.bm(25) do |x|
      x.report("Loading Code Reviews: ") {CodeReviewLoader.new.copy_parsed_tables}
      x.report("Keying Developers: ") { CodeReviewLoader.new.add_primary_keys }
      x.report("Loading CVEs: ") {CveLoader.new.load_cve}
      x.report("Loading git log commits: ") {GitLogLoader.new.load}
    end
  end

  desc "Parse data into CSV"
  task :parse => :environment do
    Benchmark.bm(25) do |x|
      x.report("Parsing raw code reviews into CSV") {
        CodeReviewParser.new.parse
      }
    end
  end
  
  desc "Alias for run:clean then run:load"
  task :clean_load => ["run:clean", "run:load"]

  desc "Optimize the tables once data is loaded"
  task :optimize => [:environment] do
    # Iterate over our models
    # TODO Refactor this out with rake run:clean so we're not repetitive
    Benchmark.bm(25) do |x|
      x.report("Optimizing tables:") do
        Dir[Rails.root.join('app/models/*.rb').to_s].each do |filename|
          klass = File.basename(filename, '.rb').camelize.constantize
          next unless klass.ancestors.include?(ActiveRecord::Base)
          klass.send(:on_optimize)
        end
      end
    end
  end

  desc "Consolidate data from join tables into one model"
  task :consolidate => [:environment] do
    Benchmark.bm(25) do |x|
      x.report("Consolidating filepaths: ") {FilepathConsolidator.new.consolidate}
      x.report("Consolidating participants: ") {DeveloperConsolidator.new.consolidate_participants}
      x.report("Consolidating contributors: ") {DeveloperConsolidator.new.consolidate_contributors}
      x.report("Consolidating participants: ") {DeveloperConsolidator.new.consolidate_reviewers}
    end
  end

  desc "Run our data verification tests"
  task :verify => :env do
    VerifyRunner.run_all
  end

  desc "Analyze the data for metrics & questions"
  task :analyze => :environment do
    # TODO: Delegate this out to a list of classes that will assemble metrics and ask questions
  end

  desc "Show current environment information"
  task :env => :environment do
    puts "\tEnv.:     #{Rails.env}"
    puts "\tData:     #{Rails.configuration.datadir}"
    puts "\tDatabase: #{Rails.configuration.database_configuration[Rails.env]["database"]}"
    puts "\tStart: #{Time.now}"
  end

  desc "Only proceed if we are SURE, or not in production"
  task :prod_check => :env do
    if 'production'.eql?(Rails.env) && !ENV['RAILS_BLAST_PRODUCTION'].eql?('YesPlease')
      $stderr.puts "WOAH! Hold on there. Are you trying to blow away our production database. Better use the proper environment variable (see our source)"
      raise "Reset with production flag not set"
    end
  end

  desc "Show some stats on the data set"
  task :stats => :env do
    stats_start = Time.now
    Stats.new.run_all
    time_taken = Time.now - stats_start
    puts "Rake run:stats took #{time_taken.round(1)}s, which is #{(time_taken/60).round(2)} minutes."
  end

end
