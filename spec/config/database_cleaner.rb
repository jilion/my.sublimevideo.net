RSpec.configure do |config|
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner[:mongoid].strategy = :truncation

    DatabaseCleaner[:active_record].strategy = :truncation
    $active_record_truncation_strategie = DatabaseCleaner.connections.pop
    DatabaseCleaner[:active_record].strategy = :transaction
    $active_record_transaction_strategie = DatabaseCleaner.connections.last

    DatabaseCleaner.clean_with(:truncation)
  end

  config.before do
    DatabaseCleaner.connections.pop
    if example.metadata[:js]
      DatabaseCleaner.connections.push $active_record_truncation_strategie
    else
      DatabaseCleaner.connections.push $active_record_transaction_strategie
      DatabaseCleaner.start
    end
  end

  config.after do
    DatabaseCleaner.clean
  end
end
