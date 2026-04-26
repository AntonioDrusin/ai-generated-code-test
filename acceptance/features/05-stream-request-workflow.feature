Feature: Stream Request Workflow
  Customers request music streams, which are then approved or denied in batch

  Scenario: Create a stream request successfully
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Active Customer" and email "active@example.com"
    And I store the customer id as "activeCustomerId"
    When I create a stream request for customer "{activeCustomerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    Then the stream request should be created successfully
    And the stream request should have status "pending"
    And the stream request should have customer_id "{activeCustomerId}"
    And the stream request should have music_stream_id "{streamId}"
    And the stream request should have requested_at "2026-04-26T10:00:00Z"
    And the stream request should have an id

  Scenario: Cannot create stream request without customer_id
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    When I create a stream request without customer_id for stream "{streamId}" at "2026-04-26T10:00:00Z"
    Then the request should fail with status 400
    And the error should be "VALIDATION_ERROR"

  Scenario: Cannot create stream request without music_stream_id
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Active Customer" and email "active@example.com"
    And I store the customer id as "activeCustomerId"
    When I create a stream request for customer "{activeCustomerId}" without music_stream_id at "2026-04-26T10:00:00Z"
    Then the request should fail with status 400
    And the error should be "VALIDATION_ERROR"

  Scenario: Cannot create stream request for non-existent customer
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    When I create a stream request for customer "99999999-9999-9999-9999-999999999999" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    Then the request should fail with status 404
    And the error should be "CUSTOMER_NOT_FOUND"

  Scenario: Cannot create stream request for non-existent stream
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Active Customer" and email "active@example.com"
    And I store the customer id as "activeCustomerId"
    When I create a stream request for customer "{activeCustomerId}" and stream "99999999-9999-9999-9999-999999999999" at "2026-04-26T10:00:00Z"
    Then the request should fail with status 404
    And the error should be "MUSIC_STREAM_NOT_FOUND"

  Scenario: Approve stream requests for active customers
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Active Customer" and email "active@example.com"
    And I store the customer id as "activeCustomerId"
    Given I create a stream request for customer "{activeCustomerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    And I store the stream request id as "requestId"
    When I approve stream requests before "2026-04-26T12:00:00Z"
    Then the approval should complete successfully
    And the approval should report 1 approved
    And the approval should report 0 denied
    And stream request "{requestId}" should have status "approved"
    And stream request "{requestId}" should have a processed_at timestamp

  Scenario: Deny stream requests for inactive customers
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Active Customer" and email "active@example.com"
    And I store the customer id as "activeCustomerId"
    Given I create a customer with name "Inactive Customer" and email "inactive@example.com"
    And I store the customer id as "inactiveCustomerId"
    And I deactivate customer "{inactiveCustomerId}"
    And I create a stream request for customer "{inactiveCustomerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    And I store the stream request id as "requestId"
    When I approve stream requests before "2026-04-26T12:00:00Z"
    Then the approval should complete successfully
    And the approval should report 0 approved
    And the approval should report 1 denied
    And stream request "{requestId}" should have status "denied"

  Scenario: Only approve requests before cutoff datetime
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Active Customer" and email "active@example.com"
    And I store the customer id as "activeCustomerId"
    Given I create a stream request for customer "{activeCustomerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    And I create a stream request for customer "{activeCustomerId}" and stream "{streamId}" at "2026-04-26T13:00:00Z"
    And I store the second stream request id as "lateRequestId"
    When I approve stream requests before "2026-04-26T12:00:00Z"
    Then the approval should report 1 approved
    And stream request "{lateRequestId}" should have status "pending"

  Scenario: Approve requests exactly at cutoff datetime
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Active Customer" and email "active@example.com"
    And I store the customer id as "activeCustomerId"
    Given I create a stream request for customer "{activeCustomerId}" and stream "{streamId}" at "2026-04-26T12:00:00Z"
    And I store the stream request id as "requestId"
    When I approve stream requests before "2026-04-26T12:00:00Z"
    Then the approval should report 1 approved
    And stream request "{requestId}" should have status "approved"

  Scenario: Batch approve mixed active and inactive customers
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Active Customer" and email "active@example.com"
    And I store the customer id as "activeCustomerId"
    Given I create a customer with name "Inactive Customer" and email "inactive@example.com"
    And I store the customer id as "inactiveCustomerId"
    And I deactivate customer "{inactiveCustomerId}"
    And I create a stream request for customer "{activeCustomerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    And I create a stream request for customer "{inactiveCustomerId}" and stream "{streamId}" at "2026-04-26T10:30:00Z"
    And I create a stream request for customer "{activeCustomerId}" and stream "{streamId}" at "2026-04-26T11:00:00Z"
    When I approve stream requests before "2026-04-26T12:00:00Z"
    Then the approval should report 2 approved
    And the approval should report 1 denied

  Scenario: Multiple customers can request same stream
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Active Customer" and email "active@example.com"
    And I store the customer id as "activeCustomerId"
    Given I create a customer with name "Customer Two" and email "customer2@example.com"
    And I store the customer id as "customer2Id"
    When I create a stream request for customer "{activeCustomerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    And I create a stream request for customer "{customer2Id}" and stream "{streamId}" at "2026-04-26T10:05:00Z"
    Then both stream requests should be created successfully

  Scenario: Customer can request same stream multiple times
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Active Customer" and email "active@example.com"
    And I store the customer id as "activeCustomerId"
    When I create a stream request for customer "{activeCustomerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    And I create a stream request for customer "{activeCustomerId}" and stream "{streamId}" at "2026-04-26T11:00:00Z"
    Then both stream requests should be created successfully
