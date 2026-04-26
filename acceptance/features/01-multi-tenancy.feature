Feature: Multi-Tenancy
  All data is scoped to a tenant. Every API request requires an X-Tenant-ID header.
  Cross-tenant data access is not permitted.

  Scenario: Authors are scoped to tenant
    Given I use one tenant
    And I create an author with name "Author One" and country "US"
    And The author is created successfully
    When I search for that author in a different tenant
    Then The author is not found

  Scenario: Customers are scoped to tenant
    Given I use one tenant
    And I create a customer with name "Customer One" and email "customer1@example.com"
    And The customer is created successfully
    When I search for that customer in a different tenant
    Then The customer is not found

  Scenario: Music streams are scoped to tenant
    Given I use one tenant
    And I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And The stream is created successfully
    When I search for that stream in a different tenant
    Then The stream is not found

  Scenario: Stream requests are scoped to tenant
    Given I use one tenant
    And I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Test Customer" and email "test@example.com"
    And I store the customer id as "customerId"
    And I create a stream request for customer "{customerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    And The stream request is created successfully
    When I search for that stream request in a different tenant
    Then The stream request is not found

  Scenario: Stream deliveries are scoped to tenant
    Given I use one tenant
    And I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Test Customer" and email "test@example.com"
    And I store the customer id as "customerId"
    And I add balance 10.00 to customer "{customerId}"
    And I create a stream request for customer "{customerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    And I approve stream requests before "2026-04-26T12:00:00Z"
    And I initiate a stream delivery for customer "{customerId}" and stream "{streamId}"
    And The stream delivery is created successfully
    When I search for that stream delivery in a different tenant
    Then The stream delivery is not found

  Scenario: Author payment reports are scoped to tenant
    Given I use one tenant as "first"
    And I create an author with name "First Tenant Author" and country "US"
    And I store the author id as "firstAuthorId"
    And I create a stream with title "First Song", author_id "{firstAuthorId}", size_mb 5.0, duration_seconds 180, cost 1.00, and genre "Pop"
    And I store the stream id as "firstStreamId"
    And I create a customer with name "First Customer" and email "first@example.com"
    And I store the customer id as "firstCustomerId"
    And I add balance 10.00 to customer "{firstCustomerId}"
    And I create a stream request for customer "{firstCustomerId}" and stream "{firstStreamId}" at "2026-04-26T10:00:00Z"
    And I approve stream requests before "2026-04-26T12:00:00Z"
    And I initiate a stream delivery for customer "{firstCustomerId}" and stream "{firstStreamId}"
    And I expire all stream deliveries
    And I use a different tenant as "second"
    And I create an author with name "Second Tenant Author" and country "UK"
    And I store the author id as "secondAuthorId"
    And I create a stream with title "Second Song", author_id "{secondAuthorId}", size_mb 5.0, duration_seconds 180, cost 2.00, and genre "Rock"
    And I store the stream id as "secondStreamId"
    And I create a customer with name "Second Customer" and email "second@example.com"
    And I store the customer id as "secondCustomerId"
    And I add balance 10.00 to customer "{secondCustomerId}"
    And I create a stream request for customer "{secondCustomerId}" and stream "{secondStreamId}" at "2026-04-26T10:00:00Z"
    And I approve stream requests before "2026-04-26T12:00:00Z"
    And I initiate a stream delivery for customer "{secondCustomerId}" and stream "{secondStreamId}"
    And I expire all stream deliveries
    When I use tenant "first"
    And I get author payment report
    Then the report should show 1 author
    And the report should only include author "{firstAuthorId}"
    And author "{firstAuthorId}" should have total payment 1.00
    When I use tenant "second"
    And I get author payment report
    Then the report should show 1 author
    And the report should only include author "{secondAuthorId}"
    And author "{secondAuthorId}" should have total payment 2.00

  Scenario: Cannot create author with foreign tenant author_id reference
    Given I use one tenant
    And I create an author with name "First Author" and country "US"
    And I store the author id as "firstAuthorId"
    When I use a different tenant
    And I try to retrieve author "{firstAuthorId}"
    Then the request should fail with status 404
    And the error should be "AUTHOR_NOT_FOUND"

  Scenario: Cannot create stream with foreign tenant author_id reference
    Given I use one tenant
    And I create an author with name "First Author" and country "US"
    And I store the author id as "firstAuthorId"
    When I use a different tenant
    And I create a stream with title "Test Song", author_id "{firstAuthorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    Then the request should fail with status 404
    And the error should be "AUTHOR_NOT_FOUND"

  Scenario: Cannot create stream request with foreign tenant customer or stream references
    Given I use one tenant as "first"
    And I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Test Customer" and email "test@example.com"
    And I store the customer id as "customerId"
    When I use a different tenant as "second"
    And I create a stream request for customer "{customerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    Then the request should fail with status 404

  Scenario: Missing tenant header should fail
    When I make a request without a tenant header to create an author
    Then the request should fail with status 400 or 401
