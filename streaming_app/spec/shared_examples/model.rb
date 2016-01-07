RSpec.shared_examples 'model create' do
  it 'is created' do
    expect{ create(model) }.to change(model, :count).by(1)
  end
end

RSpec.shared_examples 'model update' do |field, value|
  before { item.update field => value }

  it 'is updated' do
    expect(item.reload.send(field)).to eq value
  end
end

RSpec.shared_examples 'model destroy' do
  before { item.save }

  it 'is destroyed' do
    expect{ item.destroy }.to change(model, :count).by(-1)
  end
end

RSpec.shared_examples 'model trash' do
  before { item.save }

  it 'is trashed' do
    expect{ item.destroy }.to_not change(model.unscoped, :count)
  end
end

RSpec.shared_examples 'model validation' do |*fields|
  let(:new_item) { model.new }

  it 'is not created if it is not valid' do
    expect(new_item).to_not be_valid
    fields.each do |field|
      expect(new_item.errors[field].any?).to be_truthy
    end
  end
end

RSpec.shared_examples 'uniqueness validation' do |*fields|
  fields.each do |field|
    let(:item_persisted) { create model }
    let(:item) { build model }
    let(:item_different) { build model }

    it "is not valid if #{field} is not unique" do
      item.public_send "#{field}=", item_persisted.public_send(field)
      expect(item).to_not be_valid
      expect(item.errors[field].any?).to be_truthy
      item.public_send "#{field}=", item_different.public_send(field)
      expect(item).to be_valid
      expect(item.errors[field].any?).to be_falsey
    end
  end
end

RSpec.shared_examples 'uniqueness scope validation' do |*fields|
  fields.each do |field, scope|
    let(:item_persisted) { create model }
    let(:item) { build model }
    let(:item_different) { build model }

    it "is not valid if #{field} with scope #{scope} is not unique" do
      item.public_send "#{field}=", item_persisted.public_send(field)
      item.public_send "#{scope}=", item_persisted.public_send(scope)
      expect(item).to_not be_valid
      expect(item.errors[field].any?).to be_truthy
      item.public_send "#{field}=", item_different.public_send(field)
      item.public_send "#{scope}=", item_different.public_send(scope)
      expect(item).to be_valid
      expect(item.errors[field].any?).to be_falsey
    end
  end
end

RSpec.shared_examples 'string validation' do |*fields|
  fields.each do |field, limit|
    let(:item) { build model }

    it "is not valid if #{field} is too long" do
      char_limit = limit || 255
      item.send "#{field}=", Faker::Lorem.characters(char_limit + 1)
      expect(item).to_not be_valid
      expect(item.errors[field].any?).to be_truthy
      item.send "#{field}=", attributes_for(model)[field]
      expect(item).to be_valid
    end
  end
end

RSpec.shared_examples 'url validation' do |*fields|
  fields.each do |field|
    let(:item) { build model }

    it "is not valid if #{field} is not valid url" do
      item.send "#{field}=", Faker::Lorem.sentence
      expect(item).to_not be_valid
      expect(item.errors[field].any?).to be_truthy
      item.send "#{field}=", attributes_for(model)[field]
      expect(item).to be_valid
    end
  end
end

RSpec.shared_examples 'range validation' do |*fields|
  fields.each do |field, options|
    let(:item) { build model }

    it "is not valid if #{field} is at the bottom of the range" do
      item.send "#{field}=", options.first
      expect(item).to_not be_valid
      expect(item.errors[field].any?).to be_truthy
    end

    it "is not valid if #{field} is at the top of the range" do
      item.send "#{field}=", options.last
      expect(item).to_not be_valid
      expect(item.errors[field].any?).to be_truthy
    end
  end
end

RSpec.shared_examples 'option validation' do |*fields|
  fields.each do |field, options|
    let(:item) { build model }

    it "is not valid if #{field} is invalid" do
      last_value = options.is_a?(Hash) ? options.keys.max : options.max
      item.send "#{field}=", last_value.is_a?(Fixnum) ? last_value + 1 : "#{last_value}_1"
      expect(item).to_not be_valid
      expect(item.errors[field].any?).to be_truthy
      item.send "#{field}=", last_value
      expect(item).to be_valid
      expect(item.errors[field].any?).to_not be_truthy
    end
  end
end

RSpec.shared_examples 'image validation' do |*fields|
  let(:item) { build model  }

  fields.each do |field|
    it "allows to upload #{field} file" do
      item.public_send "#{field}=", default_image_file
      item.save!
      item.run_callbacks(:commit)
      item.reload
      expect(item.public_send(field)).to be_a(CarrierWave::Uploader::Base)
      expect(item.public_send(field)).to_not be_nil
    end
  end
end

RSpec.shared_examples 'belongs_to association' do |model_associated, required = false|
  let (:item) { create model }
  let (:item_associated) { create model_associated }

  it "adds #{model_associated}" do
    item.send("#{model_associated}=", item_associated)
    item.save
    expect(item.reload.send(model_associated)).to eq item_associated
  end

  if required
    it "does not remove #{model_associated}" do
      item.send("#{model_associated}=", item_associated)
      item.save
      item.send("#{model_associated}=", nil)
      expect(item).to_not be_valid
    end
  end
end

RSpec.shared_examples 'has_one association' do |model_associated, required = false|
  let (:item) { create model }
  let (:item_associated) { create model_associated }
  let (:model_association) { model_associated.to_s.downcase }

  it "adds #{model_associated}" do
    item.send("#{model_association}=", item_associated)
    item.save
    expect(item.reload.send(model_association)).to eq item_associated
  end

  if required
    it "does not remove #{model_associated}" do
      item.send("#{model_association}=", item_associated)
      item.save
      item.send("#{model_association}=", nil)
      expect(item).to_not be_valid
    end
  end
end

RSpec.shared_examples 'has_many association' do |model_associated, required = false|
  let (:item) { create model }
  let (:item_associated) { create model_associated }
  let (:model_association) { model_associated.model_name.plural }

  it "adds #{model_associated}" do
    item.send(model_association) << item_associated
    if required
      expect(item.send(model_association).count).to eq 2
    else
      expect(item.send(model_association).count).to eq 1
    end
    expect(item.send(model_association).last).to eq item_associated
  end

  it "removes #{model_associated}" do
    item.send(model_association) << item_associated
    item.send(model_association).delete(item_associated)
    if required
      expect(item.send(model_association).count).to eq 1
      expect(item.send(model_association).first).to_not be_nil
    else
      expect(item.send(model_association).count).to eq 0
      expect(item.send(model_association).first).to be_nil
    end
  end
end

RSpec.shared_examples 'habtm association' do |model_associated, required = false|
  let (:item) { create model }
  let (:item_associated) { create model_associated }
  let (:model_association) { model_associated.model_name.plural }

  it "adds #{model_associated}" do
    item.send(model_association) << item_associated
    if required
      expect(item.send(model_association).count).to eq 2
    else
      expect(item.send(model_association).count).to eq 1
    end
    expect(item.send(model_association).last).to eq item_associated
  end

  it "removes #{model_associated}" do
    item.send(model_association) << item_associated
    item.send(model_association).delete(item_associated)
    if required
      expect(item.send(model_association).count).to eq 1
      expect(item.send(model_association).first).to_not be_nil
    else
      expect(item.send(model_association).count).to eq 0
      expect(item.send(model_association).first).to be_nil
    end
  end
end

RSpec.shared_examples 'polymorphic association' do |model_association, *models_associated|
  let (:item) { create model }

  models_associated.each do |model_associated|
    it "has an association with #{model_associated}" do
      item_associated = create model_associated
      item.send "#{model_association}=", item_associated
      expect(item.send(model_association)).to be_an(model_associated)
    end
  end
end

RSpec.shared_examples 'sanitize fields' do |*fields|
  let (:item) { build model }

  fields.each do |field|
    it "removes non-utf8 chars from #{field}" do
      item.send "#{field}=", "Invalid \xAD char"
      expect(item).to be_valid
      expect(item.send(field)).to eq 'Invalid ? char'
    end

    it "removes html chars from #{field}" do
      item.send "#{field}=", "Invalid <a href=\"http://www.example.com\"></a> html"
      expect(item).to be_valid
      expect(item.send(field)).to eq 'Invalid  html'
    end

    it "removes whitespaces from #{field}" do
      item.send "#{field}=", " Whitespaces  "
      expect(item).to be_valid
      expect(item.send(field)).to eq 'Whitespaces'
    end
  end
end

RSpec.shared_examples 'token generation' do |length|
  let (:item) { build model }
  let (:item_persisted) { create model }

  it 'generates token on build' do
    expect(item.token).to be_blank
    expect(item).to be_valid
    expect(item.token).to_not be_blank
    expect(item.token.length).to eq length
  end

  it 'does not generate token when already present' do
    item.token = 'new_token'
    expect(item).to be_valid
    expect(item.token).to eq 'new_token'
  end

  it 'validates token uniqueness' do
    item.token = item_persisted.token
    expect(item).to_not be_valid
    expect(item.errors[:token].any?).to be_truthy
    item.set_token
    expect(item).to be_valid
  end
end

RSpec.shared_examples 'slug generation' do |length|
  let(:items) { create_list(model, 3, name: 'Test 123 Abc') }

  it 'creates unique slug' do
    expect(items[0].slug).to eq 'test-123-abc'
    expect(items[1].slug).to eq 'test-123-abc-1'
    expect(items[2].slug).to eq 'test-123-abc-2'
  end

  it 'creates unique slug with following number' do
    items[1].destroy
    item_4 = create(model, name: 'Test 123 Abc')
    expect(item_4.slug).to eq 'test-123-abc-3'
  end
end

RSpec.shared_examples 'deleted scope' do
  describe '.deleted' do
    let!(:item_1) { create model }
    let!(:item_2) { create model }

    it 'returns items' do
      item_1.destroy
      expect(model.deleted).to eq [item_1]
    end
  end
end

RSpec.shared_examples 'with_deleted scope' do
  describe '.with_deleted' do
    let!(:item_1) { create model }
    let!(:item_2) { create model }

    it 'returns items' do
      item_1.destroy
      expect(model.with_deleted).to eq [item_1, item_2]
    end
  end
end
