# frozen_string_literal: true

RSpec.describe SolidusFeeds do
  let(:store) { instance_double(Spree::Store, name: "The Best Store", url: "example.com") }

  before { allow(Spree::Store).to receive(:default).and_return(store) }

  specify '.title' do
    expect(described_class.title).to eq("The Best Store")
  end

  specify '.link' do
    expect(described_class.link).to eq("https://example.com")
  end

  specify '.description' do
    expect(described_class.description).to eq("Find out about new products on https://example.com first!")
  end

  specify '.language' do
    expect(described_class.language).to eq("en-us")
  end
end
