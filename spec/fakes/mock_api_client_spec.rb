# frozen_string_literal: true

require './spec/external_api/spec_helper'
require 'ruby_claim_evidence_api/external_api/response'
require 'ruby_claim_evidence_api/fakes/mock_api_client'

describe MockApiClient do
  subject(:described) { described_class.new }

  context 'when calling the Claim Evidence API' do
    it 'successfully calls the files content path' do
      response = described.send_ce_api_request(endpoint: '/files/0003E65D-0000-C118-A964-CA1AEC2925E6/content')

      expect(response).to be_a ExternalApi::Response
      expect(response.code).to eq 200
      expect(response.resp.body.encoding).to eq(Encoding::ASCII_8BIT)
    end

    it 'successfully calls the update veteran file path' do
      response = described.send_ce_api_request(endpoint: '/files/0003E65D-0000-C118-A964-CA1AEC2925E6')

      expect(response).to be_a ExternalApi::Response
      expect(response.code).to eq 200
      expect(response.body).to have_key('conversionInformation')
      expect(response.body).to have_key('currentVersionUuid')
    end

    it 'successfully calls the folders files search path' do
      response = described.send_ce_api_request(endpoint: '/folders/files:search')

      expect(response).to be_a ExternalApi::Response
      expect(response.code).to eq 200
      expect(response.body).to have_key('page')
      expect(response.body).to have_key('files')
    end
  end

  context 'when calling non-existent endpoints' do
    it 'returns not found' do
      response = described.send_ce_api_request(endpoint: '/foo/bar:baz')

      expect(response).to be_a ExternalApi::Response
      expect(response.code).to eq 404
    end
  end
end
