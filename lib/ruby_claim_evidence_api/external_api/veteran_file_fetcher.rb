# frozen_string_literal: true

module ExternalApi
  # Fetches CE API documents for a given veteran
  class VeteranFileFetcher
    def fetch_veteran_file_list(veteran_file_number:)
      get_file_list(veteran_file_number)
    end

    def get_document_content(doc_series_id:)
      ExternalApi::ClaimEvidenceService.send_ce_api_request(get_document_content_request(doc_series_id))
    end

    private

    def get_file_list(veteran_file_number)
      ExternalApi::ClaimEvidenceService.send_ce_api_request(
        endpoint: file_folders_search_endpoint,
        query: {},
        headers: x_folder_uri_header(veteran_file_number),
        method: :post,
        body: nil
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
