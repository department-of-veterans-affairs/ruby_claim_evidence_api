# frozen_string_literal: true

require 'httpi'
require 'ruby_claim_evidence_api/api_base'
require 'ruby_claim_evidence_api/external_api/response'
require_relative '../helpers/string_parser'

module ExternalApi
  # Fetches CE API documents for a given veteran
  class VeteranFileFetcher < ApiBase
    include StringParser

    def fetch_veteran_file_list(veteran_file_number:, filters: {})
      fetch_paginated_documents(
        veteran_file_number: veteran_file_number,
        filters: filters
      ).body
    end

    def fetch_veteran_file_list_by_date_range(veteran_file_number:, begin_date_range:, end_date_range:)
      filters = {
        'systemData.uploadedDateTime' => {
          'evaluationType' => 'BETWEEN',
          'value' => [begin_date_range, end_date_range]
        }
      }
      fetch_paginated_documents(
        veteran_file_number: veteran_file_number,
        filters: filters
      ).body
    end

    def get_document_content(doc_series_id:)
      # Document ID may be wrapped in curly braces, we only need the string
      doc_series_id = parse_document_id(doc_series_id)
      response = api_client.send_ce_api_request(get_document_content_request(doc_series_id))
      # Returning this value as the api call returns a byte string and not a JSON body
      response.resp.body
    end

    private

    def fetch_paginated_documents(veteran_file_number:, filters: {})
      initial_search = post_file_folders_search(veteran_file_number: veteran_file_number, body: file_folders_search_body(filters: filters))
      initial_results = initial_search.body

      total_results = initial_results['page']['totalResults'].to_i
      total_pages = initial_results['page']['totalPages'].to_i
      current_page = initial_results['page']['currentPage'].to_i

      return initial_search if total_results.zero? || current_page == total_pages

      responses = fetch_remaining_pages(initial_search, current_page, total_pages, veteran_file_number)
      build_fetch_veteran_file_list_response(responses, initial_results, initial_search)
    end

    def post_file_folders_search(veteran_file_number:, query: {}, body: nil)
      api_client.send_ce_api_request(
        endpoint: '/folders/files:search',
        query: query,
        headers: x_folder_uri_header(veteran_file_number),
        method: :post,
        body: body
      )
    end

    def fetch_remaining_pages(initial_search, current_page, total_pages, veteran_file_number)
      responses = [initial_search]

      until current_page == total_pages
        current_page += 1

        current_search = post_file_folders_search(
          veteran_file_number: veteran_file_number,
          body: file_folders_search_body(page: current_page)
        )

        responses.push(current_search)
      end

      responses
    end

    def build_fetch_veteran_file_list_response(responses, initial_results, initial_search)
      response_files = []

      responses.each do |response|
        if !response.body.nil? && !response.body.empty? && response.body.key?('files')
          response_files.concat(response.body['files'])
        else
          logger.error(response.to_json(custom_message: 'No files found in response'))
        end
      end

      final_response = { 'page': initial_results['page'], 'files': response_files }.to_json

      ExternalApi::Response.new(
        HTTPI::Response.new(initial_search.code, initial_search.resp.headers, final_response),
        nil
      )
    end

    def file_folders_search_body(results_per_page: 20, page: 1, filters: {})
      {
        "pageRequest": {
          "resultsPerPage": results_per_page,
          "page": page
        },
        "filters": filters
      }
    end

    def get_document_content_request(doc_series_id)
      {
        headers: basic_header,
        endpoint: "/files/#{doc_series_id}/content",
        method: :get
      }
    end

    def basic_header
      {
        "Content-Type": 'application/json',
        "Accept": '*/*'
      }.freeze
    end
  end
end
