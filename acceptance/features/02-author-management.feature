Feature: Author Management
  Authors are music creators who publish streams and receive payments

  Scenario: Create a new author successfully
    When I create an author with name "Hans Zimmer" and country "DE"
    Then the author should be created successfully
    And the author should have name "Hans Zimmer"
    And the author should have country "DE"
    And the author should have an id
    And the author should have a created_at timestamp

  Scenario: Create author with minimum valid data
    When I create an author with name "A" and country "US"
    Then the author should be created successfully

  Scenario: Cannot create author without name
    When I create an author with country "DE" but no name
    Then the request should fail with status 400
    And the error should be "VALIDATION_ERROR"

  Scenario: Cannot create author without country
    When I create an author with name "Test Author" but no country
    Then the request should fail with status 400
    And the error should be "VALIDATION_ERROR"

  Scenario: Create multiple authors in same tenant
    When I create an author with name "Author One" and country "US"
    And I create an author with name "Author Two" and country "UK"
    Then both authors should be created successfully
