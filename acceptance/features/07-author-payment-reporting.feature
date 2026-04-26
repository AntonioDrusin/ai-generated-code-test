Feature: Author Payment Reporting
  Calculate author payments based on completed stream deliveries

  Scenario: Calculate payment for single author with completed deliveries
    Given a tenant with id "11111111-1111-1111-1111-111111111111"
    And I use tenant "11111111-1111-1111-1111-111111111111"
    And I create an author with name "Hans Zimmer" and country "DE"
    And I store the author id as "authorId"
    And I create a stream with title "Song 1", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Soundtrack"
    And I store the stream id as "streamId"
    And I create a customer with name "Customer" and email "customer@example.com"
    And I store the customer id as "customerId"
    And I add balance 50.00 to customer "{customerId}"
    And I create 3 approved stream requests for customer "{customerId}" and stream "{streamId}"
    And I initiate 3 stream deliveries for customer "{customerId}" and stream "{streamId}"
    And I expire all stream deliveries
    When I get author payment report
    Then the report should show 1 author
    And author "{authorId}" should have 3 completed streams
    And author "{authorId}" should have total payment 2.97
    And the grand total payment should be 2.97

  Scenario: Calculate payment for multiple streams by same author
    Given a tenant with id "11111111-1111-1111-1111-111111111111"
    And I use tenant "11111111-1111-1111-1111-111111111111"
    And I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Song 1", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 1.00, and genre "Pop"
    And I store the stream id as "stream1Id"
    And I create a stream with title "Song 2", author_id "{authorId}", size_mb 4.0, duration_seconds 150, cost 1.50, and genre "Pop"
    And I store the stream id as "stream2Id"
    And I create a customer with name "Customer" and email "customer@example.com"
    And I store the customer id as "customerId"
    And I add balance 50.00 to customer "{customerId}"
    And I create 2 approved stream requests for customer "{customerId}" and stream "{stream1Id}"
    And I create 3 approved stream requests for customer "{customerId}" and stream "{stream2Id}"
    And I initiate 2 stream deliveries for customer "{customerId}" and stream "{stream1Id}"
    And I initiate 3 stream deliveries for customer "{customerId}" and stream "{stream2Id}"
    And I expire all stream deliveries
    When I get author payment report
    Then author "{authorId}" should have 5 completed streams
    And author "{authorId}" should have total payment 6.50

  Scenario: Calculate payment for multiple authors
    Given a tenant with id "11111111-1111-1111-1111-111111111111"
    And I use tenant "11111111-1111-1111-1111-111111111111"
    And I create an author with name "Author One" and country "US"
    And I store the author id as "author1Id"
    And I create an author with name "Author Two" and country "UK"
    And I store the author id as "author2Id"
    And I create a stream with title "Song 1", author_id "{author1Id}", size_mb 5.0, duration_seconds 180, cost 1.00, and genre "Pop"
    And I store the stream id as "stream1Id"
    And I create a stream with title "Song 2", author_id "{author2Id}", size_mb 4.0, duration_seconds 150, cost 2.00, and genre "Rock"
    And I store the stream id as "stream2Id"
    And I create a customer with name "Customer" and email "customer@example.com"
    And I store the customer id as "customerId"
    And I add balance 50.00 to customer "{customerId}"
    And I create 2 approved stream requests for customer "{customerId}" and stream "{stream1Id}"
    And I create 3 approved stream requests for customer "{customerId}" and stream "{stream2Id}"
    And I initiate 2 stream deliveries for customer "{customerId}" and stream "{stream1Id}"
    And I initiate 3 stream deliveries for customer "{customerId}" and stream "{stream2Id}"
    And I expire all stream deliveries
    When I get author payment report
    Then the report should show 2 authors
    And author "{author1Id}" should have total payment 2.00
    And author "{author2Id}" should have total payment 6.00
    And the grand total payment should be 8.00

  Scenario: Only count completed deliveries, not active ones
    Given a tenant with id "11111111-1111-1111-1111-111111111111"
    And I use tenant "11111111-1111-1111-1111-111111111111"
    And I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Song 1", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 1.00, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Customer" and email "customer@example.com"
    And I store the customer id as "customerId"
    And I add balance 50.00 to customer "{customerId}"
    And I create 5 approved stream requests for customer "{customerId}" and stream "{streamId}"
    And I initiate 5 stream deliveries for customer "{customerId}" and stream "{streamId}"
    And I expire 2 stream deliveries
    When I get author payment report
    Then author "{authorId}" should have 2 completed streams
    And author "{authorId}" should have total payment 2.00

  Scenario: Author with no completed deliveries shows zero payment
    Given a tenant with id "11111111-1111-1111-1111-111111111111"
    And I use tenant "11111111-1111-1111-1111-111111111111"
    And I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Song 1", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 1.00, and genre "Pop"
    When I get author payment report
    Then the report should show 1 author
    And author "{authorId}" should have 0 completed streams
    And author "{authorId}" should have total payment 0.00

  Scenario: Author with stream but no deliveries at all shows zero payment
    Given a tenant with id "11111111-1111-1111-1111-111111111111"
    And I use tenant "11111111-1111-1111-1111-111111111111"
    And I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Song 1", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 1.00, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Customer" and email "customer@example.com"
    And I store the customer id as "customerId"
    And I add balance 50.00 to customer "{customerId}"
    And I create 2 approved stream requests for customer "{customerId}" and stream "{streamId}"
    When I get author payment report
    Then author "{authorId}" should have 0 completed streams
    And author "{authorId}" should have total payment 0.00

  Scenario: Payment report is scoped to tenant
    Given a tenant with id "11111111-1111-1111-1111-111111111111"
    And I use tenant "11111111-1111-1111-1111-111111111111"
    And I create an author with name "Tenant 1 Author" and country "US"
    And I store the author id as "tenant1AuthorId"
    And I create a stream with title "Song 1", author_id "{tenant1AuthorId}", size_mb 5.0, duration_seconds 180, cost 1.00, and genre "Pop"
    And I store the stream id as "tenant1StreamId"
    And I create a customer with name "Customer" and email "customer@example.com"
    And I store the customer id as "tenant1CustomerId"
    And I add balance 50.00 to customer "{tenant1CustomerId}"
    And I create 2 approved stream requests for customer "{tenant1CustomerId}" and stream "{tenant1StreamId}"
    And I initiate 2 stream deliveries for customer "{tenant1CustomerId}" and stream "{tenant1StreamId}"
    And I expire all stream deliveries
    And I use tenant "22222222-2222-2222-2222-222222222222"
    And I create an author with name "Tenant 2 Author" and country "UK"
    And I store the author id as "tenant2AuthorId"
    When I use tenant "11111111-1111-1111-1111-111111111111"
    And I get author payment report
    Then the report should show 1 author
    And the report should only include author "{tenant1AuthorId}"
    And the grand total payment should be 2.00
