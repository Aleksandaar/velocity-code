require 'rails_helper'

RSpec.describe StreamsController do
  let(:model) { Stream }
  let(:user) { create :user }

  describe 'GET #my' do
    let!(:items) { 13.times.map { |n| Timecop.freeze(Time.current - n.hour) { create(model, creator: user) } } }
    let!(:item_1) { create model }
    let!(:item_2) { create model, :allocated, creator: user }
    before { sign_in user }

    context 'When on first page' do
      before { xhr :get, :my }

      it_behaves_like 'render template', :my

      it 'locates user_followees' do
        expect(items.take(12)).to eq assigns(:streams)
      end
    end

    context 'When on second page' do
      before { xhr :get, :my, page: 2 }

      it 'renders the next page' do
        expect(items.drop(12)).to eq assigns(:streams)
      end
    end
  end

  describe 'GET #state' do
    let!(:item) { create model }
    let(:session_id) { Faker::Lorem.characters(10) }
    let(:source_watcher) { double('source_watcher') }

    it 'returns state' do
      xhr :get, :state, { token: item.token }, session_id: session_id
      expect(response).to be_success
      expect(response_as_json).to eq(status: 'live')
    end

    it 'saves viewer' do
      expect(Stream).to receive(:find_by!).and_return item
      expect(source_watcher).to receive(:save)
      expect(SourceWatcher).to receive(:new).with(item, session_id, nil).and_return source_watcher
      xhr :get, :state, { token: item.token }, session_id: session_id
      expect(response).to be_success
    end
  end

  describe 'GET #playlist' do
    subject(:stream) { create(:stream, creator: user) }
    let(:user) { create :user }
    let!(:videos) { 2.times.map { |n| Timecop.freeze(Time.current - n.hour) { create(:archive_video, :stream_source, source: stream, title: Faker::Lorem.sentence, description: Faker::Lorem.sentence) } } }

    context 'When stream is private' do
      before { stream.update! is_private: true }

      context 'When user is not signed in' do
        before { get :playlist, token: stream.token, format: 'rss' }

        it_behaves_like 'render template', :playlist

        it 'does not locate stream' do
          expect(assigns(:stream)).to be_nil
        end

        it 'does not locate videos' do
          expect(assigns(:videos)).to be_empty
        end
      end

      context 'when user is signed in' do
        before do
          sign_in user
          get :playlist, token: stream.token, format: 'rss'
        end

        it_behaves_like 'render template', :playlist
        it_behaves_like 'locate object'

        it 'locates videos' do
          expect(assigns(:videos)).to eq videos
        end
      end
    end

    context 'when stream is not private' do
      before { get :playlist, token: stream.token, format: 'rss' }

      it_behaves_like 'render template', :playlist
      it_behaves_like 'locate object'

      it 'locates videos' do
        expect(assigns(:videos)).to eq videos
      end
    end
  end

  describe 'PUT #update' do
    let(:item) { create model, creator: user }

    context 'With valid parameters' do
      let(:title) { Faker::Lorem.sentence }
      let(:description) { Faker::Lorem.sentence }
      let(:is_private) { true }
      let(:parameters) { { token: item, stream: { title: title, description: description, is_private: true } } }

      context 'When signed out' do
        before { xhr :put, :update, parameters }

        it_behaves_like 'unauthorized'
      end

      context 'When signed in' do
        before do
          sign_in user
          xhr :put, :update, parameters
          item.reload
        end

        it 'returns success' do
          expect(response).to be_success
          expect(item.title).to eq title
          expect(item.description).to eq description
          expect(item.is_private).to eq is_private
          expect(response.body).to eq({ message: I18n.t('stream.success') }.to_json)
        end
      end
    end

    context 'With invalid parameters' do
      let(:parameters) { { token: item, stream: { title: Faker::Lorem.characters(256) } } }
      before do
        sign_in user
        xhr :put, :update, parameters
      end

      it 'returns unprocessable entity' do
        expect(response.status).to eq 422
        expect(response.body).to eq({ message: I18n.t('errors.messages.database') }.to_json)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:item) { create model, creator: user }
    let(:action) { xhr :delete, :destroy, parameters }

    context 'With valid parameters' do
      let(:parameters) { { token: item } }

      context 'When signed out' do
        before { action }

        it_behaves_like 'unauthorized'
      end

      context 'When signed in' do
        before do
          sign_in user
          action
        end

        it 'returns success' do
          expect(item.reload.deleted_at).to_not be_nil
          expect(response).to be_success
          expect(response.body).to eq({ message: I18n.t('stream.destroy') }.to_json)
        end
      end
    end

    context 'With invalid parameters' do
      let(:parameters) { { token: item } }
      before do
        item.destroy
        sign_in user
        action
      end

      it 'returns unprocessable entity' do
        expect(response.status).to eq 403
      end
    end
  end
end
