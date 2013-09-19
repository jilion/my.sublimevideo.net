require 'fast_spec_helper'
require 'sidekiq'
require 'sidekiq/testing'

require 'workers/tweets_syncer_worker'

describe TweetsSyncerWorker do
  let(:worker) { described_class.new }
  let(:twitter_tweet) { double('Twitter tweet', id: 42) }

  it 'performs async job' do
    expect { described_class.perform_async }.to change(described_class.jobs, :size).by(1)
  end

  it 'delays job in low (mysv) queue' do
    described_class.get_sidekiq_options['queue'].should eq 'low'
  end

  describe 'actual work' do
    before do
      expect(worker).to receive(:_remote_favorite_tweets_not_favorited_locally).once { [twitter_tweet] }
    end

    context 'tweet exists in the DB' do
      before { worker.stub(:_find_tweet) { local_tweet } }

      context 'tweet does not have the keyword yet' do
        let(:local_tweet) { double('Tweet', keywords: []) }

        it 'add keyword to tweet keywords set' do
          expect(local_tweet).to receive(:update_attribute).with(:favorited, true).once

          worker.perform
        end
      end
    end
  end

end
