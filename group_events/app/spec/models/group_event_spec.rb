require 'rails_helper'

RSpec.describe GroupEvent, type: :model do
  let(:model) { described_class }

  describe 'Validation' do
    let(:new_event) { build(model, name: nil)}

    it "doesn't validate draft event" do
      expect(new_event.save).to be_truthy
    end

    context 'Event published' do
      it "is validated" do
        expect{new_event.published!}.to raise_exception(ActiveRecord::RecordInvalid)
      end

      it "saves correct values" do
        new_event.name = 'New Name'
        expect(new_event.save).to be_truthy
      end
    end
  end

  describe 'Methods' do

    describe "#destroy" do
      let!(:item) { create model }

      before do
        item.destroy!
      end

      it 'soft-deletes the record' do
        expect(model.count).to eq 0
      end

      it 'keeps the deleted record' do
        expect(model.unscope(where: :deleted_at).count).to eq 1
      end

      it 'keeps the date of deletion' do
        expect(item.deleted_at).not_to eq nil
      end
    end

    describe "#duration" do
      let(:item) { build model }

      it 'converts duration to integer' do
        item.duration = 9.1
        expect(item.duration).to eq 9
      end
    end

    describe "#setters" do
      let(:item) { create model }

      it 'converts duration to integer' do
        item.duration = 9.1
        expect(item.duration).to eq 9
      end

      it 're-calculates the duration on date change' do
        item.end_date = Date.current + 10.days
        expect(item.duration).to eq 10
      end

      it 're-calculates the end_date on duration change' do
        item.duration = 10
        expect(item.end_date).to eq(Date.current + 10.days)
      end

      it 're-calculates the end_date on duration change' do
        item.start_date = Date.current + 10.days
        expect(item.end_date).to eq(Date.current + 40.days)
      end

      it 'saves the values correctly' do
        item.save
        expect(item).to eq(item)
      end

    end


  end

end
