# frozen_string_literal: true

require 'httpi'
require 'ruby_claim_evidence_api/api_base'
require 'ruby_claim_evidence_api/external_api/response'

module ExternalApi
  # Fetches CE API documents for a given veteran
  class VeteranFileFetcher < ApiBase
    def fetch_veteran_file_list(veteran_file_number:)
      initial_search = file_folders_search(veteran_file_number: veteran_file_number, body: file_folders_search_body)
      initial_results = initial_search.body

      total_pages = initial_results['page']['totalPages'].to_i
      current_page = initial_results['page']['currentPage'].to_i

      return initial_search if current_page == total_pages

      responses = fetch_remaining_pages(initial_search, current_page, total_pages, veteran_file_number)
      build_fetch_veteran_file_list_response(responses, initial_results, initial_search)
    end

    private

    def file_folders_search(veteran_file_number:, query: {}, body: nil)
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

        current_search = file_folders_search(
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
        response_files.concat(response.body['files'])
      end

      final_response = { 'page': initial_results['page'], 'files': response_files }.to_json

      ExternalApi::Response.new(
        HTTPI::Response.new(initial_search.code, initial_search.resp.headers, final_response)
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

    def x_folder_uri_header(veteran_file_number)
      {
        "X-Folder-URI": "VETERAN:FILENUMBER:#{veteran_file_number}"
      }
    end
  end
end
