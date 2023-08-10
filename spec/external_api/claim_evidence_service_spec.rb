# frozen_string_literal: true

require 'httpi'
require 'ruby_claim_evidence_api/external_api/claim_evidence_service'
require 'aws-sdk'
require './spec/external_api/spec_helper'

describe ExternalApi::ClaimEvidenceService do
  # Fake/Testing ENV variables
  let(:base_url) { "https://fake.api.claimevidence.com" }
  let(:client_secret) { "SOME-FAKE-KEY" }
  let(:doc_uuid) { "SOME-FAKE-UUID" }
  let(:service_id) { 'SOME-FAKE-SERVICE' }
  let(:aws_access_key_id) { 'dummykeyid' }
  let(:aws_secret_access_key) { 'dummysecretkey' }
  let(:aws_region) { 'us-gov-west-1' }
  let(:aws_credentials) { Aws::Credentials.new(aws_access_key_id, aws_secret_access_key) }

  before do
    ExternalApi::ClaimEvidenceService::BASE_URL = base_url
    ExternalApi::ClaimEvidenceService::JWT_TOKEN = client_secret
  end

  let(:doc_types_body) { { 'documentTypes': [{
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
    }] }.to_json
  }

  let(:alt_doc_types_body) {
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
  }

  let(:raw_ocr_from_doc_body) {
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
              "words": [{
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
              }]
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
  }

  let(:error_response_body) { { 'result': 'error', 'message': { 'token': ['error'] } }.to_json }

  let(:success_doc_types_response) do
    HTTPI::Response.new(200, {}, doc_types_body)
  end

  let(:success_alt_doc_types_response) do
    HTTPI::Response.new(200, {}, alt_doc_types_body)
  end

  let(:success_get_raw_ocr_document_response) do
    HTTPI::Response.new(200, {}, raw_ocr_from_doc_body)
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

  before do
    ExternalApi::ClaimEvidenceService::BASE_URL ||= 'https://vefs-claimevidence-dev.dev.bip.va.gov'
    ExternalApi::ClaimEvidenceService::JWT_TOKEN ||= 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJqdGkiOiI3NmQxOWE2OC03MDA1LTR
    hNjgtOWEzNC03MzEzZmI0MjMzNzMiLCJpYXQiOjE1MTYyMzkwMjIsImlzcyI6ImRldmVsb3BlclRlc3RpbmciLCJhcHBsaWNhdGlvbklEIjoiVkJNUy1
    VSSIsInVzZXJJRCI6ImNob3dhcl9zc3VwZXIiLCJzdGF0aW9uSUQiOiIzMTcifQ.33CyN4lq3WnyON2F4m4SlctTBtonBaySjf_7NDCBLl4'
  end

  context 'response success' do
    it 'document types' do
      allow(HTTPI).to receive(:get).and_return(success_doc_types_response)
      document_types = ExternalApi::ClaimEvidenceService.document_types
      expect(document_types).to be_present
    end

    it 'alt_document_types' do
      allow(HTTPI).to receive(:get).and_return(success_alt_doc_types_response)
      alt_document_types = ExternalApi::ClaimEvidenceService.alt_document_types
      expect(alt_document_types).to be_present
    end

    it 'get_ocr_document' do
      allow(HTTPI).to receive(:get).and_return(success_get_raw_ocr_document_response)
      get_ocr_document = ExternalApi::ClaimEvidenceService.get_ocr_document(doc_uuid)
      expect(get_ocr_document).to be_present
      expect(get_ocr_document).to eq('Lorem ipsum')
    end
  end

  context 'response failure' do
    subject { ExternalApi::ClaimEvidenceService.document_types }
    context 'throws fallback error' do
      it 'throws ClaimEvidenceApi::Error::ClaimEvidenceApiError' do
        allow(HTTPI).to receive(:get).and_return(error_response)
        expect { subject }.to raise_error ClaimEvidenceApi::Error::ClaimEvidenceApiError
      end
    end

    context '401' do
      it 'throws ClaimEvidenceApi::Error::ClaimEvidenceUnauthorizedError' do
        allow(HTTPI).to receive(:get).and_return(unauthorized_response)
        expect { subject }.to raise_error ClaimEvidenceApi::Error::ClaimEvidenceUnauthorizedError
      end
    end

    context '403' do
      it 'throws ClaimEvidenceApi::Error::ClaimEvidenceForbiddenError' do
        allow(HTTPI).to receive(:get).and_return(forbidden_response)
        expect { subject }.to raise_error ClaimEvidenceApi::Error::ClaimEvidenceForbiddenError
      end
    end

    context '404' do
      it 'throws ClaimEvidenceApi::Error::ClaimEvidenceNotFoundError' do
        allow(HTTPI).to receive(:get).and_return(not_found_response)
        expect { subject }.to raise_error ClaimEvidenceApi::Error::ClaimEvidenceNotFoundError
      end
    end

    context '500' do
      let!(:error_code) { 500 }
      it 'throws ClaimEvidenceApi::Error:ClaimEvidenceInternalServerError' do
        allow(HTTPI).to receive(:get).and_return(internal_server_error_response)
        expect { subject }.to raise_error ClaimEvidenceApi::Error::ClaimEvidenceInternalServerError
      end
    end
  end

  describe 'with Aws Comprehend' do
    subject { ExternalApi::ClaimEvidenceService }
    before do
      subject::CREDENTIALS = aws_credentials if subject::CREDENTIALS.access_key_id.nil?
      subject::REGION ||= aws_region
      subject::AWS_COMPREHEND_SCORE ||= 0.95
    end
    let(:ocr_data) { 'Some text string' }
    let(:stub_response) do
      [
        {
          score: 0.9825336337089539,
          text: 'Department',
          begin_offset: 1,
          end_offset: 11
        },
        {
          score: 0.9376260447502136,
          text: "Veterans Affairs\nCERTIFICATION",
          begin_offset: 15,
          end_offset: 45
        },
        {
          score: 0.994326651096344,
          text: "APPEAL\n1A",
          begin_offset: 49,
          end_offset: 58
        }
      ]
    end

    it 'initializes Aws Comprehend client with region and credentials' do
      expect(subject::REGION).not_to be_nil
      expect(subject::CREDENTIALS).not_to be_nil
      expect(subject.aws_client).not_to be_nil
      expect(subject.aws_stub_client).not_to be_nil
    end

    it 'performs #detect_key_phrase real-time analysis on ocr_data' do
      subject.aws_stub_client.stub_responses(:detect_key_phrases, { key_phrases: stub_response })
      # Stubbed data returns an Aws struct - Map the data to a hash compare
      formatted_output = subject.get_key_phrases(ocr_data, stub_response: true).map do |struct|
        {
          score: struct.score,
          text: struct.text,
          begin_offset: struct.begin_offset,
          end_offset: struct.end_offset
        }
      end
      expect(formatted_output).to eq(stub_response)
    end

    it 'filters key_phrases by score >= AWS_COMPREHEND_SCORE' do
      expect(subject.filter_key_phrases_by_score(stub_response)).to eq(['Department',"APPEAL\n1A"])
    end
  end
end
