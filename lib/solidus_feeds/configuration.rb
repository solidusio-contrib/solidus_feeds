# frozen_string_literal: true

require 'solidus_feeds/feed'

module SolidusFeeds
  class Configuration
    # Define here the settings for this extensions, e.g.:
    #
    # attr_accessor :my_setting

    def register(name, &builder)
      feeds[name.to_sym] = Feed.new.tap(&builder)
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
  end
end
