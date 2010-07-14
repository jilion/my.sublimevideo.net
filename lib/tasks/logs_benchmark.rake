desc "Heroku worker Voxcast logs parsing"
task :log_bench => :environment do
  Log::Voxcast.delay_bench_logs_parsing
end