# frozen_string_literal: true

require 'httpi'
require 'ruby_claim_evidence_api/external_api/claim_evidence_service'
require 'ruby_claim_evidence_api/models/claim_evidence_file_update_payload'
require 'ruby_claim_evidence_api/models/claim_evidence_request'
# require 'aws-sdk'
require './spec/external_api/spec_helper'
require 'webmock/rspec'

describe ExternalApi::ClaimEvidenceService do
  # Fake/Testing ENV variables
  let(:client_secret) { 'SOME-FAKE-KEY' }
  let(:doc_uuid) { 'SOME-FAKE-UUID' }
  let(:service_id) { 'SOME-FAKE-SERVICE' }
  # let(:aws_access_key_id) { 'dummykeyid' }
  # let(:aws_secret_access_key) { 'dummysecretkey' }
  # let(:aws_region) { 'us-gov-west-1' }
  # let(:aws_credentials) { Aws::Credentials.new(aws_access_key_id, aws_secret_access_key) }
  let(:file) { '/fake/file' }
  let(:file_number) { '500000000' }
  let(:doc_info) do
    {
      file: file,
      payload: {
        contentName: 'blah',
        providerData: {
          actionable: true,
          documentTypeId: 1,
          contentSource: 'VISTA',
          dateVaReceivedDocument: '2020-05-01'
        }
      }
    }
  end

  let(:claim_evidence_request) do
    ClaimEvidenceRequest.new(
      user_css_id: 'USER_858',
      station_id: 273
    )
  end

  before do
    ENV['CLAIM_EVIDENCE_SECRET'] = 'CLAIM_EVIDENCE_SECRET'
    ENV['CLAIM_EVIDENCE_ISSUER'] = 'CLAIM_EVIDENCE_ISSUER'
    ENV['CLAIM_EVIDENCE_VBMS_USER'] = 'CLAIM_EVIDENCE_VBMS_USER'
    ENV['CLAIM_EVIDENCE_STATION_ID'] = 'CLAIM_EVIDENCE_STATION_ID'
    ENV['CLAIM_EVIDENCE_API_URL'] = 'https://fake.api.claimevidence.com/'
    ENV['SSL_CERT_FILE'] = 'SSL_CERT_FILE'
    ENV['BGS_CERT_LOCATION'] = 'BGS_CERT_LOCATION'
    ENV['BGS_KEY_LOCATION'] = 'BGS_KEY_LOCATION'

    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with('BGS_CERT_LOCATION').and_return('BGS_CERT_LOCATION')
    allow(File).to receive(:read).with('BGS_KEY_LOCATION').and_return('BGS_KEY_LOCATION')
  end

  let(:doc_types_body) do
    { 'documentTypes': [
      {
        'id': 150,
        'createDateTime': '2012-01-25',
        'modifiedDateTime': '2016-03-01T16:18:56',
        'name': 'L141',
        'description': 'VA 21-8056 Request for Retirement Information from the Railroad Retirement Board
                        and Certification of Information From Department of Veterans Affairs',
        'isUserUploadable': true,
        'is526': false,
        'documentCategory': {
          'id': 70,
          'createDateTime': '2012-01-25',
          'modifiedDateTime': '2016-03-01T16:18:56',
          'description': 'Correspondence',
          'subDescription': 'Miscellaneous '
        }
      },
      {
        'id': 152,
        'createDateTime': '2012-01-25',
        'modifiedDateTime': '2016-03-01T16:18:56',
        'name': 'L143',
        'description': 'VA 21-8358 Notice to Department of Veterans Affairs of Admission to Uniformed Services Hospital',
        'isUserUploadable': true,
        'is526': false,
        'documentCategory': {
          'id': 70,
          'createDateTime': '2012-01-25',
          'modifiedDateTime': '2016-03-01T16:18:56',
          'description': 'Correspondence',
          'subDescription': 'Miscellaneous '
        }
      }
    ] }.to_json
  end

  let(:alt_doc_types_body) do
    { 'alternativeDocumentTypes': [
      {
        'id': 1,
        'createDateTime': '2016-04-13',
        'modifiedDateTime': '2016-04-13T04:00:00',
        'description': 'Notice of Disagreement (NOD)',
        'categoryDescription': 'Appeals',
        'name': 'L1'
      },
      {
        'id': 2,
        'createDateTime': '2016-04-13',
        'modifiedDateTime': '2016-04-13T04:00:00',
        'description': 'Substantive Appeal to Board of Veterans\' Appeals',
        'categoryDescription': 'Appeals',
        'name': 'L2'
      },
      {
        'id': 3,
        'createDateTime': '2016-04-13',
        'modifiedDateTime': '2016-04-13T04:00:00',
        'description': 'Statement of the Case (SOC)',
        'categoryDescription': 'Appeals',
        'name': 'L3'
      },
      {
        'id': 4,
        'createDateTime': '2016-04-13',
        'modifiedDateTime': '2016-04-13T04:00:00',
        'description': 'Supplemental Statement of the Case (SSOC)',
        'categoryDescription': 'Appeals',
        'name': 'L4'
      }
    ] }.to_json
  end

  let(:raw_ocr_from_doc_body) do
    {
      "currentVersion": {
        "file": {
          "pages": [{
            "lines": [{
              "geometry": {
                "height": 0.4,
                "left": 0.5,
                "top": 0.5,
                "width": 0.4
              },
              "pageNumber": 1,
              "text": 'Lorem ipsum',
              "words": [
                {
                  "confidence": 0.0,
                  "geometry": {
                    "height": 0.0,
                    "left": 0.0,
                    "top": 0.0,
                    "width": 0.0
                  },
                  "pageNumber": 1,
                  "text": 'Lorem'
                },
                {
                  "confidence": 0.0,
                  "geometry": {
                    "height": 0.0,
                    "left": 0.0,
                    "top": 0.0,
                    "width": 0.0
                  },
                  "pageNumber": 1,
                  "text": 'ipsum'
                }
              ]
            }],
            "pageNumber": 1,
            "text": 'Lorem ipsum'
          }],
          "text": 'Lorem ipsum',
          "totalPages": 1
        },
        "processingInformation": {
          "ocrDateTime": '2023-07-27T14:39:31.965'
        }
      }
    }.to_json
  end

  upload_document_body = {
    body: {
      "uuid": 'a89ca2f5-76e8-4d10-826c-34d34b3e386e',
      "currentVersionUuid": 'bdbe50a5-62a8-4724-abe4-7048a61b3dee'
    }
  }.to_json

  let(:error_response_body) { { 'messages': { 'token': ['error'] } }.to_json }

  let(:success_doc_types_response) do
    HTTPI::Response.new(200, {}, doc_types_body)
  end

  let(:success_alt_doc_types_response) do
    HTTPI::Response.new(200, {}, alt_doc_types_body)
  end

  let(:success_get_raw_ocr_document_response) do
    HTTPI::Response.new(200, {}, raw_ocr_from_doc_body)
  end

  let(:success_post_upload_document_response) do
    HTTPI::Response.new(200, {}, upload_document_body)
  end

  let(:error_response) do
    HTTPI::Response.new(400, {}, error_response_body)
  end
  let(:unauthorized_response) do
    HTTPI::Response.new(401, {}, error_response_body)
  end
  let(:forbidden_response) do
    HTTPI::Response.new(403, {}, error_response_body)
  end
  let(:not_found_response) do
    HTTPI::Response.new(404, {}, error_response_body)
  end
  let(:rate_limit_response) do
    HTTPI::Response.new(429, {}, error_response_body)
  end
  let(:internal_server_error_response) do
    HTTPI::Response.new(500, {}, error_response_body)
  end

  context 'response success' do
    it 'document types' do
      allow(HTTPI).to receive(:get).and_return(success_doc_types_response)
      document_types = described_class.new(claim_evidence_request: claim_evidence_request).document_types
      expect(document_types).to be_present
    end

    it 'alt_document_types' do
      allow(HTTPI).to receive(:get).and_return(success_alt_doc_types_response)
      alt_document_types = described_class.new(claim_evidence_request: claim_evidence_request).alt_document_types
      expect(alt_document_types).to be_present
    end

    it 'get_ocr_document' do
      allow(HTTPI).to receive(:get).and_return(success_get_raw_ocr_document_response)
      get_ocr_document = described_class.new(claim_evidence_request: claim_evidence_request).get_ocr_document(doc_uuid)
      expect(get_ocr_document).to be_present
      expect(get_ocr_document).to eq('Lorem ipsum')
    end

    describe 'with multipart Net HTTP request' do
      let(:upload_url) { 'https://fake.api.claimevidence.com/api/v1/rest/files' }
      let(:update_url) { 'https://fake.api.claimevidence.com/api/v1/rest/files/123456789' }

      before do
        allow(File).to receive(:binread).and_return("\x05\x00\x68\x65\x6c\x6c\x6f")

        allow(OpenSSL::PKey::RSA).to receive(:new).with('BGS_KEY_LOCATION').and_return('mock key')
        allow(OpenSSL::X509::Certificate).to receive(:new).with('BGS_CERT_LOCATION').and_return('mock cert')

        stub_request(:post, upload_url)
          .with(
            headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Content-Type' => 'multipart/form-data',
              'Host' => 'fake.api.claimevidence.com',
              'User-Agent' => 'Ruby',
              'X-Folder-Uri' => 'VETERAN:FILENUMBER:500000000'
            }
          ).to_return(status: 200, body: '', headers: {})

          stub_request(:post, update_url)
          .with(
            headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Content-Type' => 'multipart/form-data',
              'Host' => 'fake.api.claimevidence.com',
              'User-Agent' => 'Ruby',
              'X-Folder-Uri' => 'VETERAN:FILENUMBER:500000000'
            }
          ).to_return(status: 200, body: '', headers: {})
      end

      it 'uploads document' do
        described_class.new(claim_evidence_request: claim_evidence_request).upload_document(file, file_number, doc_info)
        expect(WebMock).to have_requested(:post, upload_url)
      end

      it 'updates document' do
        described_class.new(claim_evidence_request: claim_evidence_request).update_document(
          veteran_file_number: file_number,
          file_uuid: '123456789',
          file_update_payload: ClaimEvidenceFileUpdatePayload.new(
            date_va_received_document: Time.current,
            document_type_id: 'abc123',
            file_content_path: '/path/to/doc',
            file_content_source: 'encoded-string'
          )
        )
        expect(WebMock).to have_requested(:post, update_url)
      end
    end
  end

  context 'response failure' do
    context 'throws fallback error' do
      it 'throws ClaimEvidenceApi::Error::ClaimEvidenceApiError' do
        allow(HTTPI).to receive(:get).and_return(error_response)
        expect { described_class.new(claim_evidence_request: claim_evidence_request).document_types }.to raise_error ClaimEvidenceApi::Error::ClaimEvidenceApiError
      end
    end

    context '401' do
      it 'throws ClaimEvidenceApi::Error::ClaimEvidenceUnauthorizedError' do
        allow(HTTPI).to receive(:get).and_return(unauthorized_response)
        expect { described_class.new(claim_evidence_request: claim_evidence_request).document_types }.to raise_error ClaimEvidenceApi::Error::ClaimEvidenceUnauthorizedError
      end
    end

    context '403' do
      it 'throws ClaimEvidenceApi::Error::ClaimEvidenceForbiddenError' do
        allow(HTTPI).to receive(:get).and_return(forbidden_response)
        expect { described_class.new(claim_evidence_request: claim_evidence_request).document_types }.to raise_error ClaimEvidenceApi::Error::ClaimEvidenceForbiddenError
      end
    end

    context '404' do
      it 'throws ClaimEvidenceApi::Error::ClaimEvidenceNotFoundError' do
        allow(HTTPI).to receive(:get).and_return(not_found_response)
        expect { described_class.new(claim_evidence_request: claim_evidence_request).document_types }.to raise_error ClaimEvidenceApi::Error::ClaimEvidenceNotFoundError
      end
    end

    context '500' do
      let!(:error_code) { 500 }
      it 'throws ClaimEvidenceApi::Error:ClaimEvidenceInternalServerError' do
        allow(HTTPI).to receive(:get).and_return(internal_server_error_response)
        expect { described_class.new(claim_evidence_request: claim_evidence_request).document_types }.to raise_error ClaimEvidenceApi::Error::ClaimEvidenceInternalServerError
      end
    end
  end

  # context 'with Aws Comprehend' do
  #   subject { ExternalApi::ClaimEvidenceService }
  #   before do
  #     subject::REGION ||= aws_region
  #     subject::AWS_COMPREHEND_SCORE ||= 0.95
  #     stub_request(:put, 'http://169.254.169.254/latest/api/token')
  #       .with(
  #         headers: {
  #           'Accept' => '*/*',
  #           'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
  #           'User-Agent' => 'aws-sdk-ruby2/2.11.632',
  #           'X-Aws-Ec2-Metadata-Token-Ttl-Seconds' => '21600'
  #         }
  #       ).to_return(status: 200, body: '', headers: {})

  #     stub_request(:get, 'http://169.254.169.254/latest/meta-data/iam/security-credentials/')
  #       .with(
  #         headers: {
  #           'Accept' => '*/*',
  #           'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
  #           'User-Agent' => 'aws-sdk-ruby2/2.11.632'
  #         }
  #       ).to_return(status: 200, body: '', headers: {})
  #   end
  #   let(:ocr_data) { 'Some text string' }
  #   let(:stub_response) do
  #     [
  #       {
  #         score: 0.9825336337089539,
  #         text: 'Department',
  #         begin_offset: 1,
  #         end_offset: 11
  #       },
  #       {
  #         score: 0.9376260447502136,
  #         text: "Veterans Affairs\nCERTIFICATION",
  #         begin_offset: 15,
  #         end_offset: 45
  #       },
  #       {
  #         score: 0.994326651096344,
  #         text: "APPEAL\n1A",
  #         begin_offset: 49,
  #         end_offset: 58
  #       }
  #     ]
  #   end

  #   it 'initializes Aws Comprehend client with region' do
  #     expect(subject::REGION).not_to be_nil
  #     expect(subject.aws_client).not_to be_nil
  #     expect(subject.aws_stub_client).not_to be_nil
  #   end

  #   it 'performs #detect_key_phrase real-time analysis on ocr_data' do
  #     subject.aws_stub_client.stub_responses(:detect_key_phrases, { key_phrases: stub_response })
  #     # Stubbed data returns an Aws struct - Map the data to a hash compare
  #     formatted_output = subject.get_key_phrases(ocr_data, stub_response: true).map do |struct|
  #       {
  #         score: struct.score,
  #         text: struct.text,
  #         begin_offset: struct.begin_offset,
  #         end_offset: struct.end_offset
  #       }
  #     end
  #     expect(formatted_output).to eq(stub_response)
  #   end

  #   it 'filters key_phrases by score >= AWS_COMPREHEND_SCORE' do
  #     expect(subject.filter_key_phrases_by_score(stub_response)).to eq(%W[Department APPEAL\n1A])
  #   end

  #   it 'retrieves key_phrases from CE API document' do
  #     subject.aws_stub_client.stub_responses(:detect_key_phrases, { key_phrases: stub_response })
  #     allow(HTTPI).to receive(:get).and_return(success_get_raw_ocr_document_response)
  #     output = subject.get_key_phrases_from_document(doc_uuid, stub_response: true)
  #     expect(output).to eq(%W[Department APPEAL\n1A])
  #   end
  # end
end
