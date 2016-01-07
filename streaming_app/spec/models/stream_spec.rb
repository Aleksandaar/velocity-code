require 'rails_helper'

RSpec.describe Stream, type: :model do
  let(:model) { described_class }

  describe 'CRUD operations' do
    subject(:item) { create model }

    it_behaves_like 'model create'
    it_behaves_like 'model update', :status, 'allocated'
    it_behaves_like 'model destroy'
    it_behaves_like 'model trash'
  end

  describe 'Validation' do
    it_behaves_like 'model validation', :creator
    it_behaves_like 'token generation', 6
    it_behaves_like 'string validation', :title
    it_behaves_like 'sanitize fields', :title, :description
  end

  describe 'Associations' do
    it_behaves_like 'belongs_to association', :creator do
      let (:item_associated) { create User }
    end
    it_behaves_like 'has_many association', ArchiveVideo
    it_behaves_like 'has_one association', :archive_video
    it_behaves_like 'has_one association', :promoted_archive_video do
      let (:item_associated) { create :archive_video, :promoted  }
    end
    it_behaves_like 'habtm association', Channel
    it_behaves_like 'habtm association', GpsLocation
  end

  describe 'Callbacks' do
    describe '#notify_followers' do
      subject(:item) { build model, :allocated }

      context 'when receives message' do
        it 'status changed to live' do
          expect(item).to receive(:notify_followers)
          item.update status: :live
        end
      end

      context 'when does not receive message' do
        it 'is not live' do
          expect(item).to_not receive(:notify_followers)
          item.update status: Stream.statuses[:ended]
        end

        it 'status does not change' do
          expect(item).to_not receive(:notify_followers)
          item.update title: Faker::Lorem.sentence
        end

        it 'is private' do
          item.creator.streaming_default_private = true
          expect(item).to_not receive(:notify_followers)
          item.update! status: Stream.statuses[:live]
        end
      end
    end

    describe 'destroy gps_locations' do
      subject(:item) { create model, gps_locations: [create(:gps_location)] }

      it 'destroys gps_locations' do
        expect{ item.destroy }.to change { item.gps_locations.count }.by(-1)
      end
    end

    describe '#set_privacy' do
      context 'when user has streaming_default_private true' do
        let(:user) { create :user, :streaming_default_private }
        subject(:item) { build model, creator: user }

        it 'is_private changes to true' do
          expect{ item.save! }.to change{ item.is_private }.from(false).to(true)
        end
      end

      context 'when user has streaming_default_private false' do
        subject(:item) { build model }

        it 'is_private does not change' do
          expect{ item.save! }.to_not change{ item.is_private }
        end
      end
    end
  end

  describe 'Methods' do
    subject(:item) { build model }
    before { item.valid? }

    describe '#name' do
      it 'returns creator name' do
        expect(item.name).to eq item.creator.name
      end
    end

    describe '#hds_url, #hls_url' do
      it 'returns hds_url' do
        expect(item.hds_url).to eq "#{ENV.fetch('WOWZA_LIVESTREAM_URL')}/stream/#{item.rtmp_name}/manifest.f4m"
      end

      it 'returns hls_url' do
        expect(item.hls_url).to eq "#{ENV.fetch('WOWZA_LIVESTREAM_URL')}/stream/#{item.rtmp_name}/playlist.m3u8"
      end
    end

    describe '#rtmp_name' do
      before { item.creator.update_column :email, 'user-email%$&@example.com' }

      it 'returns rtmp_name' do
        expect(item.rtmp_name).to eq "s-#{item.token}"
      end
    end

    describe '#thumbnail' do
      it 'returns thumbnail' do
        expect(item.thumbnail).to eq ActionController::Base.helpers.asset_path('default_live_thumbnail.jpg')
      end
    end

    describe '#live_views_counter' do
      it 'returns 0' do
        expect(item.live_views_counter).to eq 0
      end

      it 'returns 1' do
        SourceWatcher.new(item, SecureRandom.urlsafe_base64).save
        expect(item.live_views_counter).to eq 1
      end
    end
  end

  describe 'Methods' do
    subject(:item) { build model }
    before { item.valid? }

    describe '#name' do
      it 'returns creator name' do
        expect(item.name).to eq item.creator.name
      end
    end

    describe '#hds_url, #hls_url' do
      it 'returns hds_url' do
        expect(item.hds_url).to eq "#{ENV.fetch('WOWZA_LIVESTREAM_URL')}/stream/#{item.rtmp_name}/manifest.f4m"
      end

      it 'returns hls_url' do
        expect(item.hls_url).to eq "#{ENV.fetch('WOWZA_LIVESTREAM_URL')}/stream/#{item.rtmp_name}/playlist.m3u8"
      end
    end

    describe '#rtmp_name' do
      before { item.creator.update_column :email, 'user-email%$&@example.com' }

      it 'returns rtmp_name' do
        expect(item.rtmp_name).to eq "s-#{item.token}"
      end
    end

    describe '#owner?' do
      let(:user) { create :user }

      it 'returns true' do
        expect(item.owner?(item.creator)).to be_truthy
      end

      it 'returns false' do
        expect(item.owner?(user)).to be_falsey
      end
    end

    describe '#current_stream' do
      it 'returns self' do
        expect(item.current_stream).to eq item
      end
    end

    describe '#chat_room' do
      it 'returns chat_room' do
        expect(item.chat_room).to eq "stream-#{item.token}"
      end
    end

    describe '#url' do
      it 'returns url' do
        expect(item.url).to match "#{Rails.application.config.action_mailer.default_url_options[:host]}/profile/#{item.creator.username}/watch/#{item.token}"
      end
    end

    describe '#to_param' do
      it 'returns token' do
        expect(item.to_param).to eq item.token
      end
    end

    describe '#channel_names' do
      it 'returns channel names' do
        item.channels = [ Channel.new(name: "A"), Channel.new(name: "B") ]
        expect(item.channel_names).to eq "A, B"
      end

      it 'returns name placeholder' do
        expect(item.channel_names).to eq I18n.t('stream.no_channels')
      end
    end

    describe '#api_model_data' do
      let(:api_hash) { { type: item.class.name.downcase, token: item.token, status: item.status, title: item.title, description: item.description, views_counter: item.views_counter, date_time: item.updated_at, gps_location: item.gps_locations.limit(5).map(&:api_model_data), url: item.webapp_url, hls_url: item.hls_url, is_private: item.is_private, rtmp_stream_id: item.rtmp_name, creator: item.creator.api_model_data, archive_videos: item.archive_videos.map(&:api_model_data) } }

      before { mock_wowza_ips }

      context 'when stream is live' do
        before { api_hash[:live_views_counter] = 0 }

        it 'returns api hash' do
          item_as_json = item.api_model_data
          expect(item_as_json).to eq api_hash.deep_stringify_keys!
        end
      end

      context 'when stream is not live' do
        before { item.status = 0 }

        it 'returns api hash' do
          item_as_json = item.api_model_data
          expect(item_as_json).to eq api_hash.deep_stringify_keys!
        end
      end
    end

    describe '#api_model_data_create' do
      before { mock_wowza_ips }
      let(:api_hash) { { type: item.class.name.downcase, token: item.token, status: item.status, title: item.title, description: item.description, views_counter: item.views_counter, date_time: item.updated_at, gps_location: item.gps_locations.limit(5).map(&:api_model_data), url: item.webapp_url, hls_url: item.hls_url, is_private: item.is_private, rtmp_stream_id: item.rtmp_name, creator: item.creator.api_model_data, live_views_counter: 0,  archive_videos: item.archive_videos.map(&:api_model_data), rtmp_endpoint: item.rtmp_endpoint } }

      it 'returns rtmp_endpoint' do
        item_as_json = item.api_model_data_create
        expect(item_as_json).to eq api_hash.merge!(rtmp_endpoint: item_as_json['rtmp_endpoint']).deep_stringify_keys!
      end
    end

    describe '#notify_followers' do
      it 'enqueues resque worker' do
        expect(Resque).to receive(:enqueue).with(NotifyFollowers, item.token)
        item.notify_followers
      end
    end

    describe '#set_channel' do
      it 'enqueues resque worker' do
        expect(Resque).to receive(:enqueue).with(SetChannel, item.token)
        item.send(:set_channel)
      end
    end

    describe '#by_title_or_description' do
      let(:pattern) { 'emerge' }

      let(:item_1) { build model, title: "#{pattern}" }
      let(:item_2) { build model, description: "#{pattern}" }
      let(:item_3) { build model, title: "Title #{pattern}" }
      let(:item_4) { build model, description: "Description #{pattern}" }
      let(:item_5) { build model, title: "Title ##{pattern}15 title" }
      let(:item_6) { build model, description: "Description ##{pattern}15 description" }
      let(:item_7) { build model }

      it 'returns true' do
        expect(item_1.title_description_matches?(pattern)).to be_truthy
        expect(item_2.title_description_matches?(pattern)).to be_truthy
        expect(item_3.title_description_matches?(pattern)).to be_truthy
        expect(item_4.title_description_matches?(pattern)).to be_truthy
        expect(item_5.title_description_matches?(pattern)).to be_truthy
        expect(item_6.title_description_matches?(pattern)).to be_truthy
      end

      it 'returns false' do
        expect(item_7.title_description_matches?(pattern)).to be_falsey
      end
    end
  end

  describe 'Wowza' do
    subject(:item) { create model }

    it '#stop!' do
      expect(Wowza).to receive(:drop_encoder).with(item.rtmp_name)
      expect{ item.stop! }.to change{ item.status }.from('live').to('user_stopped')
    end

    it '#drop' do
      expect(Wowza).to receive(:drop_encoder).with(item.rtmp_name)
      item.drop
    end

    it '#rtmp' do
      expect(Wowza).to receive(:generate_encoder_pool_rtmp_url).with(item.rtmp_name)
      item.rtmp
    end

    it '#rtmp_watch' do
      expect(Wowza).to receive(:generate_watch_pool_rtmp_url).with(item.rtmp_name)
      item.rtmp_watch
    end

    it '#pool_server_ip' do
      expect(Wowza).to receive(:get_pool_stream_ip).with(item.rtmp_name)
      item.pool_server_ip
    end
  end

  describe 'Scopes' do
    describe '.watchable' do
      let!(:item_1) { create model }
      let!(:item_2) { create model, :ended }
      let!(:item_3) { create model, :allocated }

      it 'returns items' do
        expect(model.watchable).to match_array([item_1, item_2])
      end
    end

    describe '.promoted' do
      let!(:item_1) { create model }
      let!(:item_2) { create model, :ended }
      let!(:item_3) { create model, :ended }
      let!(:item_4) { create model, :ended }
      let!(:archive_video_2) { create_list :archive_video, 2, :promoted, :stream_source, source: item_2 }
      let!(:archive_video_3) { create :archive_video, :stream_source, source: item_3 }

      it 'returns items' do
        expect(model.promoted).to match_array([item_1, item_2])
      end
    end

    it_behaves_like 'deleted scope'
    it_behaves_like 'with_deleted scope'
  end
end
