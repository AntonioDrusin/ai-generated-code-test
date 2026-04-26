Feature: Stream Delivery Workflow
  Customers initiate stream deliveries from approved requests, and deliveries expire after a short time

  Scenario: Initiate stream delivery successfully
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Test Customer" and email "test@example.com"
    And I store the customer id as "customerId"
    And I add balance 10.00 to customer "{customerId}"
    And I create a stream request for customer "{customerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    And I approve stream requests before "2026-04-26T12:00:00Z"
    When I initiate a stream delivery for customer "{customerId}" and stream "{streamId}"
    Then the stream delivery should be initiated successfully
    And the stream delivery should have status "active"
    And the stream delivery should have customer_id "{customerId}"
    And the stream delivery should have music_stream_id "{streamId}"
    And the stream delivery should have a stream_url
    And the stream delivery should have an initiated_at timestamp
    And the stream delivery should have an expires_at timestamp
    And the customer balance should be 9.01

  Scenario: Cannot initiate delivery without approved request
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Test Customer" and email "test@example.com"
    And I store the customer id as "customerId"
    And I add balance 10.00 to customer "{customerId}"
    And I create a stream request for customer "{customerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    And I approve stream requests before "2026-04-26T12:00:00Z"
    And I create a customer with name "No Request Customer" and email "norequest@example.com"
    And I store the customer id as "noRequestCustomerId"
    And I add balance 10.00 to customer "{noRequestCustomerId}"
    When I initiate a stream delivery for customer "{noRequestCustomerId}" and stream "{streamId}"
    Then the request should fail with status 409
    And the error should be "NO_APPROVED_REQUEST"

  Scenario: Cannot initiate delivery for inactive customer
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Test Customer" and email "test@example.com"
    And I store the customer id as "customerId"
    And I add balance 10.00 to customer "{customerId}"
    And I create a stream request for customer "{customerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    And I approve stream requests before "2026-04-26T12:00:00Z"
    And I deactivate customer "{customerId}"
    When I initiate a stream delivery for customer "{customerId}" and stream "{streamId}"
    Then the request should fail with status 409
    And the error should be "CUSTOMER_INACTIVE"

  Scenario: Cannot initiate delivery with insufficient balance
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Test Customer" and email "test@example.com"
    And I store the customer id as "customerId"
    And I add balance 10.00 to customer "{customerId}"
    And I create a stream request for customer "{customerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    And I approve stream requests before "2026-04-26T12:00:00Z"
    And I create a customer with name "Poor Customer" and email "poor@example.com"
    And I store the customer id as "poorCustomerId"
    And I add balance 0.50 to customer "{poorCustomerId}"
    And I create a stream request for customer "{poorCustomerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    And I approve stream requests before "2026-04-26T12:00:00Z"
    When I initiate a stream delivery for customer "{poorCustomerId}" and stream "{streamId}"
    Then the request should fail with status 409
    And the error should be "INSUFFICIENT_BALANCE"
    And the customer "{poorCustomerId}" balance should remain 0.50

  Scenario: Cannot initiate delivery for non-existent customer
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Test Customer" and email "test@example.com"
    And I store the customer id as "customerId"
    And I add balance 10.00 to customer "{customerId}"
    And I create a stream request for customer "{customerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    And I approve stream requests before "2026-04-26T12:00:00Z"
    When I initiate a stream delivery for customer "99999999-9999-9999-9999-999999999999" and stream "{streamId}"
    Then the request should fail with status 404
    And the error should be "CUSTOMER_NOT_FOUND"

  Scenario: Cannot initiate delivery for non-existent stream
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Test Customer" and email "test@example.com"
    And I store the customer id as "customerId"
    And I add balance 10.00 to customer "{customerId}"
    And I create a stream request for customer "{customerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    And I approve stream requests before "2026-04-26T12:00:00Z"
    When I initiate a stream delivery for customer "{customerId}" and stream "99999999-9999-9999-9999-999999999999"
    Then the request should fail with status 404
    And the error should be "MUSIC_STREAM_NOT_FOUND"

  Scenario: Use oldest approved request when multiple exist
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Test Customer" and email "test@example.com"
    And I store the customer id as "customerId"
    And I add balance 10.00 to customer "{customerId}"
    And I create a stream request for customer "{customerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    And I approve stream requests before "2026-04-26T12:00:00Z"
    And I create a stream request for customer "{customerId}" and stream "{streamId}" at "2026-04-26T11:00:00Z"
    And I approve stream requests before "2026-04-26T12:00:00Z"
    When I initiate a stream delivery for customer "{customerId}" and stream "{streamId}"
    Then the stream delivery should be initiated successfully
    And the stream delivery should reference the first approved request

  Scenario: Expire stream deliveries
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Test Customer" and email "test@example.com"
    And I store the customer id as "customerId"
    And I add balance 10.00 to customer "{customerId}"
    And I create a stream request for customer "{customerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    And I approve stream requests before "2026-04-26T12:00:00Z"
    And I initiate a stream delivery for customer "{customerId}" and stream "{streamId}"
    And I store the stream delivery id as "deliveryId"
    And the stream delivery expires at "2026-04-26T13:00:05Z"
    When I expire stream deliveries before "2026-04-26T13:00:10Z"
    Then the expiration should complete successfully
    And the expiration should report 1 expired
    And stream delivery "{deliveryId}" should have status "done"
    And stream delivery "{deliveryId}" should have a completed_at timestamp

  Scenario: Do not expire deliveries after cutoff
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Test Customer" and email "test@example.com"
    And I store the customer id as "customerId"
    And I add balance 10.00 to customer "{customerId}"
    And I create a stream request for customer "{customerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    And I approve stream requests before "2026-04-26T12:00:00Z"
    And I initiate a stream delivery for customer "{customerId}" and stream "{streamId}"
    And I store the stream delivery id as "deliveryId"
    And the stream delivery expires at "2026-04-26T13:00:10Z"
    When I expire stream deliveries before "2026-04-26T13:00:05Z"
    Then the expiration should report 0 expired
    And stream delivery "{deliveryId}" should have status "active"

  Scenario: Expire deliveries exactly at cutoff
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Test Customer" and email "test@example.com"
    And I store the customer id as "customerId"
    And I add balance 10.00 to customer "{customerId}"
    And I create a stream request for customer "{customerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    And I approve stream requests before "2026-04-26T12:00:00Z"
    And I initiate a stream delivery for customer "{customerId}" and stream "{streamId}"
    And I store the stream delivery id as "deliveryId"
    And the stream delivery expires at "2026-04-26T13:00:05Z"
    When I expire stream deliveries before "2026-04-26T13:00:05Z"
    Then the expiration should report 1 expired
    And stream delivery "{deliveryId}" should have status "done"

  Scenario: Expire multiple deliveries
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Test Customer" and email "test@example.com"
    And I store the customer id as "customerId"
    And I add balance 10.00 to customer "{customerId}"
    And I create a stream request for customer "{customerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    And I approve stream requests before "2026-04-26T12:00:00Z"
    And I initiate a stream delivery for customer "{customerId}" and stream "{streamId}"
    And I create a stream request for customer "{customerId}" and stream "{streamId}" at "2026-04-26T11:00:00Z"
    And I approve stream requests before "2026-04-26T12:00:00Z"
    And I initiate a stream delivery for customer "{customerId}" and stream "{streamId}"
    And all deliveries expire at "2026-04-26T13:00:05Z"
    When I expire stream deliveries before "2026-04-26T13:00:10Z"
    Then the expiration should report 2 expired

  Scenario: Multiple deliveries for same stream deduct balance each time
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Test Customer" and email "test@example.com"
    And I store the customer id as "customerId"
    And I add balance 10.00 to customer "{customerId}"
    And I create a stream request for customer "{customerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    And I approve stream requests before "2026-04-26T12:00:00Z"
    And I create a stream request for customer "{customerId}" and stream "{streamId}" at "2026-04-26T11:00:00Z"
    And I approve stream requests before "2026-04-26T12:00:00Z"
    When I initiate a stream delivery for customer "{customerId}" and stream "{streamId}"
    And I initiate a stream delivery for customer "{customerId}" and stream "{streamId}"
    Then the customer balance should be 8.02

  Scenario: Stream delivery URL should be unique
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Test Customer" and email "test@example.com"
    And I store the customer id as "customerId"
    And I add balance 10.00 to customer "{customerId}"
    And I create a stream request for customer "{customerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    And I approve stream requests before "2026-04-26T12:00:00Z"
    And I initiate a stream delivery for customer "{customerId}" and stream "{streamId}"
    And I store the stream url as "url1"
    And I create a stream request for customer "{customerId}" and stream "{streamId}" at "2026-04-26T11:00:00Z"
    And I approve stream requests before "2026-04-26T12:00:00Z"
    And I initiate a stream delivery for customer "{customerId}" and stream "{streamId}"
    And I store the stream url as "url2"
    Then the two stream urls should be different
