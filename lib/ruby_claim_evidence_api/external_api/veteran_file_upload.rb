# frozen_string_literal: true

require 'ruby_claim_evidence_api/api_base'

module ExternalApi
  # upload documents through CE API for a given veteran
  class VeteranFileUpload 
    def upload_veteran_file(file_path:, veteran_file_number:, doc_info:) 
        payload = {
          contentName: doc_info.content_name,
          providerData: {
            contentSource: doc_info.content_source,
            documentTypeId: doc_info.document_type_id,
            dateVaReceivedDocument: doc_info.date_va_received_document
          }
        }

    ExternalApi::ClaimEvidenceService.upload_document(file_path, veteran_file_number,payload)
    end
  end
end
