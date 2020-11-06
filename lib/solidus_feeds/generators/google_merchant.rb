# frozen_string_literal: true

require 'builder'

module SolidusFeeds
  module Generators
    # The GoogleMerchant XML feed as described in https://support.google.com/merchants/answer/7052112.
    class GoogleMerchant
      attr_accessor :products, :host

      def initialize(products, host:)
        self.products = products
        self.host = host
      end

      def call(io)
        builder = Builder::XmlMarkup.new(target: io, indent: 0)
        render_template(builder)
      end

      def render_template(xml)
        xml.rss version: "2.0", "xmlns:g" => "http://base.google.com/ns/1.0" do
          xml.channel do
            xml.title SolidusFeeds.title
            xml.link SolidusFeeds.link
            xml.description SolidusFeeds.description
            xml.language SolidusFeeds.language
            products.find_each do |product|
              xml.item do
                xml.tag! 'g:id', id(product)
                xml.tag! 'g:title', title(product)
                xml.tag! 'g:description', description(product)
                xml.tag! 'g:link', link(product)
                xml.tag! 'g:image_link', image_link(product)
                xml.tag! 'g:condition', condition(product)
                xml.tag! 'g:price', price(product)
                xml.tag! 'g:availability', availability(product)
                xml.tag! 'g:brand', brand(product)
                xml.tag! 'g:mpn', mpn(product)
                xml.tag! 'g:google_product_category', google_product_category_id(product)
              end
            end
          end
        end
      end

      def id(product)
        product.id
      end

      def title(product)
        product.name
      end

      def description(product)
        product.description
      end

      def link(product)
        spree_routes.product_url(product, host: host)
      end

      def image_link(product)
        return unless product.images.any?

        attachment_url = product.images.first.attachment.url(:large)
        asset_host = ActionController::Base.asset_host

        URI.join(asset_host, attachment_url).to_s
      end

      # Must be "new", "refurbished", or "used".
      def condition(product)
        product.property("condition") || "new"
      end

      def price(product)
        Spree::Money.new(product.price).money.format(symbol: false, with_currency: true)
      end

      # Must be "in stock", "preorder" or "out of stock"
      def availability(product)
        product.master.in_stock? ? 'in stock' : 'out of stock'
      end

      def brand(product)
        product.property("brand") || SolidusFeeds.title
      end

      def mpn(product)
        product.master.sku
      end

      def google_product_category_id(product)
        # Must be selected from https://support.google.com/merchants/answer/1705911
        product.property("google_product_category_id")
      end

      private

      def spree_routes
        @spree_routes ||= Spree::Core::Engine.routes.url_helpers
      end
    end
  end
end
