# frozen_string_literal: true

require 'ruby_claim_evidence_api/api_base'

module ExternalApi
  # upload documents through CE API for a given veteran
  class VeteranFileUploader < ApiBase
    def upload_veteran_file(file_path:, claim_evidence_request:, veteran_file_number:, doc_info:)
      api_client(claim_evidence_request: claim_evidence_request).upload_document(
        file_path,
        veteran_file_number,
        file_upload_payload(doc_info)
      )
    end

    private

    def file_upload_payload(doc_info)
      {
        contentName: doc_info.content_name,
        providerData: {
          contentSource: doc_info.content_source,
          documentTypeId: doc_info.document_type_id,
          dateVaReceivedDocument: doc_info.date_va_received_document,
          subject: doc_info.subject,
          newMail: doc_info.new_mail
        }
      }
    end
  end
end
