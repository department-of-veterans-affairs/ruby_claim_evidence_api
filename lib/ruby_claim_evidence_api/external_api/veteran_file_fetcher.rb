# frozen_string_literal: true

module ExternalApi
  # Fetches CE API documents for a given veteran
  class VeteranFileFetcher
    def fetch_veteran_file_list(veteran_file_number:)
      get_file_list(veteran_file_number: veteran_file_number)
    end

    private

    def get_file_list(veteran_file_number:, query: {}, body: nil)
      ExternalApi::ClaimEvidenceService.send_ce_api_request(
        endpoint: file_folders_search_endpoint,
        query: query,
        headers: x_folder_uri_header(veteran_file_number),
        method: :post,
        body: body
      )
    end

    def file_folders_search_endpoint
      '/folders/files:search'
    end

    def x_folder_uri_header(veteran_file_number)
      {
        "X-Folder-URI": "VETERAN:FILENUMBER:#{veteran_file_number}"
      }
    end
  end
end
