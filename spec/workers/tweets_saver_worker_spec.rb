require 'fast_spec_helper'
require 'sidekiq'
require 'sidekiq/testing'

require 'workers/tweets_saver_worker'

Tweet = Class.new unless defined?(Tweet)

describe TweetsSaverWorker do
  let(:worker) { described_class.new }
  let(:twitter_tweet) { double('Twitter tweet', id: 42) }

  it 'performs async job' do
    expect { described_class.perform_async('rymai') }.to change(described_class.jobs, :size).by(1)
  end

  it 'delays job in low (mysv) queue' do
    expect(described_class.get_sidekiq_options['queue']).to eq 'my-low'
  end

  describe 'actual work' do
    before do
      expect(worker).to receive(:_remote_search).with('rymai', nil).once { double(max_id: 1, results: [twitter_tweet]) }
      expect(worker).to receive(:_remote_search).with('rymai', 1).once { double(max_id: 2, results: []) }
    end

    context 'tweet does not exist in the DB yet' do
      before { allow(worker).to receive(:_find_tweet) { nil } }

      it 'creates tweets in the DB from real tweets' do
        expect(Tweet).to receive(:create_from_twitter_tweet!).once

        worker.perform('rymai')
      end
    end

    context 'tweet exists in the DB' do
      before { allow(worker).to receive(:_find_tweet) { local_tweet } }

      context 'tweet does not have the keyword yet' do
        let(:local_tweet) { double('Tweet', keywords: []) }

        it 'add keyword to tweet keywords set' do
          expect(Tweet).not_to receive(:create_from_twitter_tweet!)
          expect(local_tweet).to receive(:add_to_set).with(keywords: 'rymai').once

          worker.perform('rymai')
        end
      end

      context 'tweet has the keyword yet' do
        let(:local_tweet) { double('Tweet', keywords: ['rymai']) }

        it 'does not add keyword to tweet keywords set' do
          expect(Tweet).not_to receive(:create_from_twitter_tweet!)
          expect(local_tweet).not_to receive(:add_to_set).with(keywords: 'rymai')

          worker.perform('rymai')
        end
      end
    end
  end

end
