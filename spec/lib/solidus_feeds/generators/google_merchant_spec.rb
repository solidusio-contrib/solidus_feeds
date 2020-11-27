# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe SolidusFeeds::Generators::GoogleMerchant do
  subject(:generator) { described_class.new(products, host: 'https://example.com') }

  let(:products) do
    Spree::Product.where(id: [
      create(:product, id: 123, slug: 'pro1', name: 'A product', price: 123.45, description: 'product description', sku: 'PRD1'), # rubocop:disable Layout/LineLength
      create(:product, id: 456, slug: 'pro2', name: 'Another product', price: 678.90, description: 'another product description', sku: 'PRD2'), # rubocop:disable Layout/LineLength
    ]).order(:id)
  end
  let(:product) { products.first }
  let(:store) { instance_double(Spree::Store, name: "The Best Store", url: "example.com") }

  before { allow(Spree::Store).to receive(:default).and_return(store) }

  before(:each, with_images: true) do
    allow(ActionController::Base).to receive(:asset_host).and_return('https://assets.example.com')
    Spree::Image.create! viewable: products.first.master, attachment_file_name: 'foo.png', id: 234
  end

  describe '#call', :with_images do
    describe 'generated XML' do
      def expect_xml_content(xpath)
        expect(xml.xpath(xpath, 'g' => "http://base.google.com/ns/1.0").text)
      end

      let(:xml) do
        io = StringIO.new
        generator.call(io)
        Nokogiri::XML(io.string)
      end

      it 'includes the tags with the expected values' do
        aggregate_failures do
          expect_xml_content('//channel/title').to eq('The Best Store')
          expect_xml_content('//channel/link').to eq('https://example.com')
          expect_xml_content('//channel/description').to eq('Find out about new products on https://example.com first!')
          expect_xml_content('//channel/language').to eq('en-us')
          expect_xml_content('//channel/item[1]/g:id').to eq('123')
          expect_xml_content('//channel/item[1]/g:title').to eq('A product')
          expect_xml_content('//channel/item[1]/g:description').to eq('product description')
          expect_xml_content('//channel/item[1]/g:link').to eq('https://example.com/products/pro1')
          expect_xml_content('//channel/item[1]/g:image_link').to eq("https://assets.example.com/spree/products/234/large/foo.png") # rubocop:disable Layout/LineLength
          expect_xml_content('//channel/item[1]/g:condition').to eq('new')
          expect_xml_content('//channel/item[1]/g:price').to eq('123.45 USD')
          expect_xml_content('//channel/item[1]/g:availability').to eq('out of stock')
          expect_xml_content('//channel/item[1]/g:brand').to eq('The Best Store')
          expect_xml_content('//channel/item[1]/g:mpn').to eq('PRD1')
          expect_xml_content('//channel/item[1]/g:google_product_category').to eq('')
        end
      end
    end
  end

  specify '#id' do
    product = instance_double(Spree::Product, id: 789)

    expect(generator.id(product)).to eq(789)
  end

  specify '#title' do
    product = instance_double(Spree::Product, name: "Foo Bar")

    expect(generator.title(product)).to eq("Foo Bar")
  end

  specify '#description' do
    product = instance_double(Spree::Product, description: "Foo Bar")

    expect(generator.description(product)).to eq("Foo Bar")
  end

  specify '#link' do
    product = instance_double(Spree::Product, to_param: "123-my-product")

    expect(generator.link(product)).to eq("https://example.com/products/123-my-product")
  end

  specify '#image_link', :with_images do
    expect(generator.image_link(products.first)).to eq("https://assets.example.com/spree/products/234/large/foo.png")
    expect(generator.image_link(products.second)).to eq(nil)
  end

  specify '#condition' do
    products.first.set_property("condition", "foo-bar")

    expect(generator.condition(product)).to eq("foo-bar")
  end

  specify '#price' do
    product = instance_double(Spree::Product, price: 321.45);

    expect(generator.price(product)).to eq("321.45 USD")
  end

  describe '#availability' do
    it 'is "in stock" when available' do
      allow(product.master).to receive(:in_stock?).and_return(true)

      expect(generator.availability(product)).to eq("in stock")
    end

    it 'is "out of stock" when unavailable' do
      allow(product.master).to receive(:in_stock?).and_return(false)

      expect(generator.availability(product)).to eq("out of stock")
    end
  end

  specify '#brand' do
    product.set_property("brand", "foo-bar")

    expect(generator.brand(product)).to eq("foo-bar")
    expect(generator.brand(products.second)).to eq("The Best Store")
  end

  specify '#mpn' do
    allow(product.master).to receive(:sku).and_return("FOOO_123_SKU")

    expect(generator.mpn(product)).to eq("FOOO_123_SKU")
  end

  specify '#google_product_category_id' do
    product.set_property("google_product_category_id", "123456")

    expect(generator.google_product_category_id(product)).to eq("123456")
  end
end
