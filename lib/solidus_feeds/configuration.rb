# frozen_string_literal: true

require 'solidus_feeds/feed'

module SolidusFeeds
  class Configuration
    # Define here the settings for this extensions, e.g.:
    #
    # attr_accessor :my_setting

    def register(name, &builder)
      feeds[name.to_sym] = Feed.new(&builder)
    end

    def find(name)
      feeds.fetch(name)
    end

    private

    def feeds
      @feeds ||= {}
    end
  end

  class << self
    attr_writer :title, :link, :description, :language

    def configuration
      @configuration ||= Configuration.new
    end

    alias config configuration

    def reset_config!
      @configuration
    end

    def configure
      yield configuration
    end

    def title
      @title ||= ::Spree::Store.default.name
    end

    def link
      @link ||= "https://#{::Spree::Store.default.url}"
    end

    def description
      @description ||= "Find out about new products on https://#{::Spree::Store.default.url} first!"
    end

    def language
      @language ||= 'en-us'
    end
  end
end
