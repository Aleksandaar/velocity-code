require 'spec_helper'

describe Line::PClient::Variant do
  let!(:aaa) { create(:airport, code: 'AAA') }
  let!(:bbb) { create(:airport, code: 'BBB') }
  let!(:ccc) { create(:airport, code: 'CCC') }

  describe "::new" do
    it "requires that all mandatory keys are passed" do
      expect {
        described_class.new(blah: 'a')
      }.to raise_error(ArgumentError)
    end

    it "returns an instance of Variant initialized with passed arguments" do
      variant = described_class.new(tail_number: '12345',
                                    user_match: true,
                                    price: '$10'.to_money,
                                    aircraft_type: '12',
                                    legs: [
                                      { origin: aaa, destination: bbb,
                                        departs_at: aaa.time_zone!.parse("2013-10-28 13:56"),
                                        arrives_at: bbb.time_zone!.parse("2013-10-28 15:16") }
                                    ])
      expect(variant).to be_a Line::PClient::Variant
      expect(variant.tail_number).to eq '112345'
      expect(variant.user_match).to be_true
      expect(variant.price).to eq '$10'.to_money
      expect(variant.aircraft_type).to eq 'pc-12'
      expect(variant).to have(1).leg

    end
  end

end
