require 'rails_helper'

RSpec.describe Api::V1::GroupEventsController do
  let(:item) { create :group_event }

  before do
    allow(GroupEvent).to receive(:find).with('1').and_return item
    allow(GroupEvent).to receive(:find).with('2').and_return nil
  end


  describe 'GET #show' do
    context 'When success' do
      before do
        get :show, { id: 1 }
      end

      it 'returns success response' do
        expect(response).to be_success
        expect(response.body).to eq({
          status: 'OK',
          group_event: item.to_hash
        }.to_json)
      end
    end

    context 'When failature' do
      before do
        get :show, { id: 2 }
      end

      it 'returns error response' do
        expect(response.status).to eq 404
      end
    end
  end

  describe 'GET #edit' do
    context 'When success' do
      before do
        patch :edit,  id: 1, group_event: { name: 'New Name', duration: 10 }
      end

      it 'returns success response' do
        expect(response).to be_success
        expect(response.body).to eq({
          status: 'OK',
          group_event: item.to_hash
        }.to_json)
      end
    end

    context 'When failature' do
      before do
        patch :edit,  id: 1, group_event: { name: nil, status: :published }
      end

      it 'returns error response' do
        expect(response.status).to eq 500
      end
    end
  end

    describe 'GET #destroy' do
    context 'When success' do
      before do
        delete :destroy, id: 1
      end

      it 'returns success response' do
        expect(response).to be_success
        expect(response.body).to eq({status: 'OK'}.to_json)
      end
    end

    context 'When failature' do
      before do
        delete :destroy, id: 2
      end

      it 'returns error response' do
        expect(response).not_to be_success
      end
    end
  end


end
