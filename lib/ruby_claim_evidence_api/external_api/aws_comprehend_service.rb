# frozen_string_literal: true

require 'aws-sdk'

module ExternalApi
  ## Initializes AWS Client through aws-sdk gem with :text_array and :language_code
  class AWSComprehendService
    attr_accessor :text_array, :language_code

    attr_reader :results

    #TODO: Need to figure out what these environment variables actually are
    #TODO: Need to decide on how to save "score" - save to ENV variable or initialize it with the client?
    CREDENTIALS = ENV['credentials']
    REGION = ENV['region']
    SCORE = ENV['score']

    @client = Aws::Comprehend::Client.new(
      region: REGION,
      credentials: CREDENTIALS
    )

    def initialize(text_array: [], language_code: "en")
      @text_array = text_array
      @language_code = language_code
      @results = {}
    end

    #TODO: Need to add async error handling
    
    # Real Time Analysis Methods for Single Text String
    def detect_key_phrases
      res = @client.detect_key_phrases(@text_array[0], @language_code)
      @results[:key_phrases] = res
    end

    def detect_entities
      res = @client.detect_key_phrases(@text_array[0], @language_code)
      @results[:entities] = res
    end

    # Real Time Analysis Methods for Multiple Text Strings
    def batch_detect_key_phrases
      res = @client.batch_detect_key_phrases(@text_array, @language_code)
      @results[:key_phrases] = res
    end

    def batch_detect_entities
      res = @client.batch_detect_entities(@text_array, @language_code)
      @results[:entities] = res
    end
  end
end
