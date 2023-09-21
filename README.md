# ruby_claim_evidence_api
Ruby library for connecting to the [Claim Evidence API](https://github.com/department-of-veterans-affairs/bip-vefs-claimevidence/).

## Overview
Currently, this gem is able to interact with the following endpoints of the Claim Evidence API.

### `GET /documenttypes`
Call `document_types` to retrieve available document types:

```ruby
ExternalApi::ClaimEvidenceService.document_types
```

### `GET /files/{doc_series_id}/data/ocr`
Call `get_ocr_document(doc.series_id)` to get all of the content for a document:

```ruby
# Assume use of a VBMS Document model
doc = Document.find_by(criteria: "here")

ExternalApi::ClaimEvidenceService.get_ocr_document(doc.series_id)
```

## Testing

### In Local Rails Console
Internally, the app uses a `Fakes` module to mock API behavior. The required setup steps are as follows:

1. Install and configure `devvpn`.
    - _TODO_: Get more info re. this and link to docs.
1. Add files needed by Faraday.
    1. Access the example certs [located here](https://github.com/department-of-veterans-affairs/bip-vefs-claimevidence/tree/development/Postman%20Suites/client%20certs).
    1. Copy the `.crt` file locally and note the path for later.
    1. Copy the `.key` file locally and note the path for later.
1. In your shell, set the following environment variables:
    - `JWT_TOKEN`:
        - **_NOTE_**: Some CE API endpoints need correct user roles in order to get a successful response.
            - For example, calling the OCR endpoint requires that the user attached to the request's JWT have a specific scanner role.
            - More information on available roles can be found [here](http://example.com).
                -  _TODO_: Get link to available roles documentation
        - For the `Fakes` module, JWT tokens do not auto-generate with each request, so you will need to either manually create one or use an existing token.
            - Using an existing token (recommended):
                - Use one of the JWTs from the Postman environments listed [here](https://github.com/department-of-veterans-affairs/bip-vefs-claimevidence/tree/development/Postman%20Suites).
            - Creating a new token:
                - Directions and requirements can be found [here](https://github.com/department-of-veterans-affairs/bip-vefs-claimevidence/wiki/JWT-Authorization).

    - `BASE_URL`:
        - This will depend on the environment you're wanting to test.
        - For example, `https://vefs-claimevidence-int.dev.bip.va.gov` is the URL for the INT environment.
    - `HTTP_PROXY`:
        - You need to have an AIDE user and password, which you can find more info on [here](https://github.com/department-of-veterans-affairs/bip-developer-guides/wiki/How-to-update-your-AIDE-password-(MacOS)).
        - The required format is: `http://aideusername:aidepassword@127.0.0.1:9443`
    - `KEY_LOCATION`: Path to `.key` file from earlier.
    - `CERT_LOCATION`: Path to `.crt` file from earlier.
    - `CERT_PASSWORD`: Use `vbmsclient`.
1. Relaunch your shell or source your shell's config file to load the variables you set above.
1. In your local Rails console, you can now use `Fakes::ClaimEvidenceService`. For example:
    - `Fakes::ClaimEvidenceService.document_types`
    - `Fakes::ClaimEvidenceService.get_ocr_document(doc.series_id)`

### In UAT Environments
In many UAT environments, the gem is preconfigured and can be used via `ExternalApi::ClaimEvidenceService`:

```ruby
ExternalApi::ClaimEvidenceService.document_types
ExternalApi::ClaimEvidenceService.get_ocr_document(doc.series_id)
```

## Example Usage

### Getting All OCR Content for a Document
This will return all of the documents that contain the search word or phrase inside the document:

```ruby
match_docs = []

person.documents.each do |doc|
  query = ExternalApi::ClaimEvidenceService.get_ocr_document(doc.series_id)
  if query.downcase.include("search term here")
    match_docs << doc
  end
end
```
