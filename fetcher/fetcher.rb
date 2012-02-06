#!/usr/bin/env ruby

require 'rubygems'
require 'mongo'
require 'scrobbler'
require 'scrobbler-ng-utils/misc/rate-limiter'
require 'scrobbler-ng-utils/cache/mongo'
require 'set'


# Load the configuration
require File.join(File.dirname(__FILE__), 'config')

# Initialise the scobbler-ng library
Scrobbler::Base.api_key = $config[:lastfm][:apikey]

class Fetcher

    def initialize(config)
        @friends = Set.new
        @scanned_users = Set.new
        @config = config
        @mongo = Mongo::Connection.new(@config[:mongo][:host], @config[:mongo][:port]).db(@config[:mongo][:database])
        @mongo.authenticate(@config[:mongo][:user], @config[:mongo][:password])
        @cache = Scrobbler::Cache::Mongo.new(@mongo.collection(@config[:mongo][:cache_collection]))
        Scrobbler::Base.add_cache(@cache)
        @users = @mongo.collection(@config[:mongo][:user_collection])
        @artists = @mongo.collection(@config[:mongo][:artist_collection])
    end

    def handle_artist(artist)
        # Try to find artist in result table
        artist_entry = @artists.find_one({'name' => artist.name})
        # If not already in the database or outdated, update them
        if artist_entry.nil? # TODO: or 'too old' or 'forced update?
            begin
                top_tags = artist.top_tags.map {|tag| {'name' => tag.name, 'count' => tag.count}}
                @artists.insert({'name' => artist.name, 'top_tags' => top_tags, 'updated_at' => Time.now})
            rescue Scrobbler::ApiError => error
                puts error
            end
        end
    end

    def handle_songride_user(user_entry)
        user = Scrobbler::User.new(:name => user_entry['username'])
        # Add all friends to the fetching queue
        user.friends.each do |friend|
            @friends.add(friend.name.downcase)
        end
        handle_lastfm_user(user_entry)
    end

    def handle_lastfm_user(user_entry)
        user = Scrobbler::User.new(:name => user_entry['username'])
        library = Scrobbler::Library.new(user)
        # Check if a user should be scanned again
        if user_entry['updated_at'].nil? # TODO: or 'too old' or 'forced update?'
            print user_entry['username'] + ' '
            library.artists.each { |artist| handle_artist(artist) }
            user_entry['artists'] = library.artists.map {|artist| {'name' => artist.name, 'count' => artist.playcount}}
            user_entry['friends'] = user.friends.map {|friend| friend.name}
            user_entry['updated_at'] = Time.now
            if user_entry['_id'].nil? then
                @users.insert(user_entry)
            else
                @users.update({'_id' => user_entry['_id']}, user_entry)
            end
        end
        @scanned_users.add(user.name.downcase)
    end

    def iterate_users
        @users.find({"wants_statistics" => true}).each do |user_entry|
            handle_songride_user(user_entry)
        end
    end

    def iterate_friends
        friends = @friends - @scanned_users
        num = friends.count
        friend_count = 0
        friends.each do |friend_name|
            friend_count += 1
            print "\r#{friend_count}/#{num} "
            user_entry = @users.find_one({'username' => friend_name})
            user_entry = {'username' => friend_name} if user_entry.nil?
            handle_lastfm_user(user_entry)
        end
    end
end

fetcher = Fetcher.new $config
fetcher.iterate_users
fetcher.iterate_friends

