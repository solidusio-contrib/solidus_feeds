# Solidus Feeds

[![CircleCI](https://circleci.com/gh/solidusio-contrib/solidus_feeds.svg?style=shield)](https://circleci.com/gh/solidusio-contrib/solidus_feeds)
[![codecov](https://codecov.io/gh/solidusio-contrib/solidus_feeds/branch/master/graph/badge.svg)](https://codecov.io/gh/solidusio-contrib/solidus_feeds)

<!-- Explain what your extension does. -->
A framework for producing and publishing feeds on Solidus.

## Installation

Add solidus_feeds to your Gemfile:

```ruby
gem 'solidus_feeds'
```

Bundle your dependencies and run the installation generator:

```shell
bin/rails generate solidus_feeds:install
```

## Out of the box usage

<!-- Explain how to use your extension once it's been installed. -->

Let's say that you want to generate a XML feed for products belonging to the `Shoes` taxon,
consumable by Google Merchant compatible marketplaces  and make it publicly available on your
`my-bucket` S3 bucket at the path `foo/bar.xml`.

To register the feed you'd need to add the following code to an initializer such as
`config/initializers/solidus.rb` or better yet `config/initializers/solidus_feeds.rb`

```ruby
Rails.application.config.to_prepare do
  SolidusFeeds.config.register :google_merchant_shoes do |feed|
    taxon = Spree::Taxon.find_by(name: "Shoes")
    products = Spree::Product.available.in_taxon(taxon)

    feed.generator = SolidusFeeds::Generators::GoogleMerchant.new(products, host: Spree::Store.default.url)
    feed.publisher = SolidusFeeds::Publishers::S3.new(bucket: "my-bucket", object_key: "foo/bar.xml")
  end
end
```

Then make your Solidus app generate and publish the feed by calling the following line. It's
recommended to call it in a background job, especially when generating feeds with large amounts of
products.

```ruby
SolidusFeeds.configuration.find(:google_merchant_shoes).publish
```

Having it in a background job makes it easier to:

- Launch it manually from the backend dashboard
- Make it refresh periodically via cron, sidekiq-scheduler, Heroku scheduler or similar
- Refresh the feed when receiving data from a [webhook](https://github.com/solidusio-contrib/solidus_webhooks)
  or after specific Solidus events

## Serving the feed from the products controller (legacy)

We suggest to avoid this behaviour because it could be resource intensive, especially with a large
number of products.

If you want to support the legacy behaviour of [`solidus_product_feed`](https://github.com/solidusio-contrib/solidus_product_feed)
and publish a XML feed at `/products.rss`, you can add the following decorator:

```ruby
# app/decorators/controllers/solidus_feeds/spree/products_controller.rb

module SolidusFeeds
  module Spree
    module ProductsControllerDecorator
      def self.prepended(klass)
        klass.respond_to :rss, only: :index
        klass.before_action :verify_requested_format!, only: :index
      end

      def index
        render as: :xml, body: load_feed_products if request.format.rss?
        super
      end

      private

      def load_feed_products
        @products = ::Spree::Product.all
        io = StringIO.new
        SolidusFeeds::Generators::GoogleMerchant
          .new(@products, host: 'https://example.com')
          .call(io)
        io.rewind
        io.read
      end

      ::Spree::ProductsController.prepend self
    end
  end
end
```

## Publishing backends

### S3

If you don't want to configure a S3 `client` each time, you can load your AWS config in an
initializer:

```ruby
# config/initializers/aws.rb

Aws.config[:profile] = 'my-profile'
```

Then config your S3 publisher specifying the `bucket`, `object_key` and an optional `client` if you
need custom configuration on a per-publisher basis.

```ruby
# config/initializers/solidus_feeds.rb

Rails.application.config.to_prepare do
  SolidusFeeds.config.register :all_products do |feed|
    feed.generator = SolidusFeeds::Generators::GoogleMerchant.new(
      Spree::Product.all,
      host: Spree::Store.default.url
    )
    feed.publisher = SolidusFeeds::Publishers::S3.new(
      bucket: "foo",
      object_key: "bar/my_feed.xml",
      client: Aws::S3::Client.new(…), # This is optional - use only if a custom config is needed
    )
  end
end
# visit https://s3.us-east-1.amazonaws.com/foo/bar/my_feed.xml
```

### Static file

To publish the feed directly from an app directory (e.g. the `public` directory), you can use the
Static File Publisher as such:

```ruby
# config/initializers/solidus_feeds.rb

Rails.application.config.to_prepare do
  SolidusFeeds.config.register :all_products do |feed|
    feed.generator = SolidusFeeds::Generators::GoogleMerchant.new(
      Spree::Product.all,
      host: Spree::Store.default.url
    )
    feed.publisher = SolidusFeeds::Publishers::StaticFile.new(
      path: Rails.root.join('public/products.xml')
    )
  end
end
```

## Builtin Marketplace format generators

- Google Merchant XML: compatible with Google Merchant and Facebook/Instagram feeds

## Creating your own Generators and Publishers

Both the generator and the publisher are expected to respond to `#call`.

The publisher's `#call` method is expected to yield an IO-like object that responds to `#<<`.

### Example

For example a simple feed that will publish recently added products to Rails' public folder in JSON
format would look like this:

```ruby
class FilePublisher < Struct.new(:path)
  def call
    File.open(path, 'w') do |file|
      yield file
    end
  end
end

class JsonProductFeed < Struct.new(:products)
  def call(io)
    products.find_each do |product|
      io << product.to_json
    end
  end
end

SolidusFeeds.register :recent_products do |feed|
  recent_products = Spree::Product.where(created_at: Time.now..2.weeks.ago)

  feed.generator = JsonProductFeed.new(recent_products)
  feed.publisher = FilePublisher.new(Rails.root.join("public/product.json")
end
```

## Development

### Testing the extension

First bundle your dependencies, then run `bin/rake`. `bin/rake` will default to building the dummy
app if it does not exist, then it will run specs. The dummy app can be regenerated by using
`bin/rake extension:test_app`.

```shell
bin/rake
```

To run [Rubocop](https://github.com/bbatsov/rubocop) static code analysis run

```shell
bundle exec rubocop
```

When testing your application's integration with this extension you may use its factories.
Simply add this require statement to your spec_helper:

```ruby
require 'solidus_feeds/factories'
```

### Running the sandbox

To run this extension in a sandboxed Solidus application, you can run `bin/sandbox`. The path for
the sandbox app is `./sandbox` and `bin/rails` will forward any Rails commands to
`sandbox/bin/rails`.

Here's an example:

```
$ bin/rails server
=> Booting Puma
=> Rails 6.0.2.1 application starting in development
* Listening on tcp://127.0.0.1:3000
Use Ctrl-C to stop
```

### Updating the changelog

Before and after releases the changelog should be updated to reflect the up-to-date status of
the project:

```shell
bin/rake changelog
git add CHANGELOG.md
git commit -m "Update the changelog"
```

### Releasing new versions

Please refer to the dedicated [page](https://github.com/solidusio/solidus/wiki/How-to-release-extensions) on Solidus wiki.

## License

Copyright (c) 2021 Nebulab SRLs, released under the New BSD License.
