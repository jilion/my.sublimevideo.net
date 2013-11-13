RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner[:mongoid].strategy = :truncation
  end

  config.before do |example|
    with_transaction_callbacks = example.metadata[:with_transaction_callbacks]

    config.use_transactional_fixtures = !with_transaction_callbacks

    if with_transaction_callbacks
      DatabaseCleaner[:active_record].strategy = :truncation
    else
      DatabaseCleaner[:active_record].strategy = :transaction
    end
    DatabaseCleaner.start
  end

  config.after do |example|
    DatabaseCleaner.clean
  end
end
