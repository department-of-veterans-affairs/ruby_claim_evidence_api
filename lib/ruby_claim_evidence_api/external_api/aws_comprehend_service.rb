# frozen_string_literal: true

require 'aws-sdk'

module ExternalApi
  ## Initializes AWS Client through aws-sdk gem with :text_array and :language_code
  class AwsComprehendService
    attr_accessor :text_array, :language_code

    attr_reader :results

    # TODO: Need to decide on how to save "score" - save to ENV variable or initialize it with the client?
    CREDENTIALS = Aws::Credentials.new(
      ENV['AWS_ACCESS_KEY_ID'],
      ENV['AWS_SECRET_ACCESS_KEY']
    )

    REGION = ENV['AWS_DEFAULT_REGION']
    SCORE = ENV['AWS_COMPREHEND_SCORE']

    @client = Aws::Comprehend::Client.new(
      region: REGION,
      credentials: CREDENTIALS
    )

    def initialize(text_array: [], language_code: 'en')
      @text_array = text_array
      @language_code = language_code
      @results = {}
    end

    def single_text_input
      {
        text: @text_array[0],
        language_code: @language_code
      }
    end

    def multiple_text_input
      {
        text_list: @text_array,
        language_code: @language_code
      }
    end

    # Real Time Analysis Methods for Single Text String
    def detect_key_phrases
      response = @client.detect_key_phrases(single_text_input)
      relevant_key_phrases = response.key_phrases.map { |key_phrase| key_phrase.text if key_phrase.score > SCORE }
      @results[:key_phrases] = relevant_key_phrases
      relevant_key_phrases
    rescue StandardError => e
      puts e
    end

    def detect_entities
      response = @client.detect_key_phrases(single_text_input)
      relevant_entities = response.entities.map { |entity| entity.text if entity.score > SCORE }
      @results[:entities] = relevant_entities
      relevant_entities
    rescue StandardError => e
      puts e
    end

    # Real Time Analysis Methods for Multiple Text Strings
    def batch_detect_key_phrases
      response = @client.batch_detect_key_phrases(multiple_text_input)
      relevant_key_phrases = response.key_phrases.map { |key_phrase| key_phrase.text if key_phrase.score > SCORE }
      @results[:key_phrases] = relevant_key_phrases
      relevant_key_phrases
    rescue StandardError => e
      puts e
    end

    def batch_detect_entities
      response = @client.batch_detect_entities(multiple_text_input)
      relevant_entities = response.entities.map { |entity| entity.text if entity.score > SCORE }
      @results[:entities] = relevant_entities
      relevant_entities
    rescue StandardError => e
      puts e
    end
  end
end
