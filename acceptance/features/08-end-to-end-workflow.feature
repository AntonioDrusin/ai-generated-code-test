Feature: End-to-End Workflow
  Complete customer stream consumption flow from author creation to payment calculation

  Scenario: Complete happy path workflow
    # Setup tenant
    Given a tenant with id "11111111-1111-1111-1111-111111111111"
    And I use tenant "11111111-1111-1111-1111-111111111111"
    
    # 1. Create author
    Given I create an author with name "Hans Zimmer" and country "DE"
    And I store the author id as "authorId"
    
    # 2. Create music streams
    And I create a stream with title "Time", author_id "{authorId}", size_mb 8.5, duration_seconds 295, cost 0.99, and genre "Soundtrack"
    And I store the stream id as "stream1Id"
    And I create a stream with title "Dream Is Collapsing", author_id "{authorId}", size_mb 7.2, duration_seconds 254, cost 0.99, and genre "Soundtrack"
    And I store the stream id as "stream2Id"
    
    # 3. Create customers
    And I create a customer with name "Alice" and email "alice@example.com"
    And I store the customer id as "aliceId"
    And I create a customer with name "Bob" and email "bob@example.com"
    And I store the customer id as "bobId"
    
    # 4. Top up balances
    And I add balance 50.00 to customer "{aliceId}"
    And I add balance 30.00 to customer "{bobId}"
    
    # 5. Customers request streams
    And I create a stream request for customer "{aliceId}" and stream "{stream1Id}" at "2026-04-26T10:00:00Z"
    And I create a stream request for customer "{aliceId}" and stream "{stream2Id}" at "2026-04-26T10:05:00Z"
    And I create a stream request for customer "{bobId}" and stream "{stream1Id}" at "2026-04-26T10:10:00Z"
    And I create a stream request for customer "{bobId}" and stream "{stream2Id}" at "2026-04-26T10:15:00Z"
    
    # 6. Approve requests
    When I approve stream requests before "2026-04-26T12:00:00Z"
    Then the approval should report 4 approved
    
    # 7. Initiate deliveries
    And I initiate a stream delivery for customer "{aliceId}" and stream "{stream1Id}"
    And I initiate a stream delivery for customer "{aliceId}" and stream "{stream2Id}"
    And I initiate a stream delivery for customer "{bobId}" and stream "{stream1Id}"
    And I initiate a stream delivery for customer "{bobId}" and stream "{stream2Id}"
    
    # 8. Check balances deducted
    Then the customer "{aliceId}" balance should be 48.02
    And the customer "{bobId}" balance should be 28.02
    
    # 9. Expire deliveries
    And I expire all stream deliveries
    
    # 10. Check author payments
    When I get author payment report
    Then the report should show 1 author
    And author "{authorId}" should have 4 completed streams
    And author "{authorId}" should have total payment 3.96
    And the grand total payment should be 3.96

  Scenario: Workflow with inactive customer denial
    # Setup tenant
    Given a tenant with id "11111111-1111-1111-1111-111111111111"
    And I use tenant "11111111-1111-1111-1111-111111111111"
    
    # Setup
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 1.00, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Active Customer" and email "active@example.com"
    And I store the customer id as "activeId"
    And I create a customer with name "Will Be Inactive" and email "inactive@example.com"
    And I store the customer id as "inactiveId"
    And I add balance 20.00 to customer "{activeId}"
    And I add balance 20.00 to customer "{inactiveId}"
    
    # Create requests
    And I create a stream request for customer "{activeId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    And I create a stream request for customer "{inactiveId}" and stream "{streamId}" at "2026-04-26T10:05:00Z"
    
    # Deactivate one customer before approval
    And I deactivate customer "{inactiveId}"
    
    # Approve - should deny inactive customer
    When I approve stream requests before "2026-04-26T12:00:00Z"
    Then the approval should report 1 approved
    And the approval should report 1 denied
    
    # Only active customer can initiate delivery
    And I initiate a stream delivery for customer "{activeId}" and stream "{streamId}"
    And the customer "{activeId}" balance should be 19.00
    
    # Inactive customer cannot initiate
    When I initiate a stream delivery for customer "{inactiveId}" and stream "{streamId}"
    Then the request should fail with status 409
    And the error should be "CUSTOMER_INACTIVE"
    
    # Complete delivery and check payment
    And I expire all stream deliveries
    And I get author payment report
    Then author "{authorId}" should have 1 completed streams
    And author "{authorId}" should have total payment 1.00

  Scenario: Workflow with insufficient balance
    # Setup tenant
    Given a tenant with id "11111111-1111-1111-1111-111111111111"
    And I use tenant "11111111-1111-1111-1111-111111111111"
    
    # Setup
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    And I create a stream with title "Expensive Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 5.00, and genre "Pop"
    And I store the stream id as "streamId"
    And I create a customer with name "Poor Customer" and email "poor@example.com"
    And I store the customer id as "customerId"
    And I add balance 2.00 to customer "{customerId}"
    
    # Request and approve
    And I create a stream request for customer "{customerId}" and stream "{streamId}" at "2026-04-26T10:00:00Z"
    And I approve stream requests before "2026-04-26T12:00:00Z"
    
    # Try to initiate - should fail
    When I initiate a stream delivery for customer "{customerId}" and stream "{streamId}"
    Then the request should fail with status 409
    And the error should be "INSUFFICIENT_BALANCE"
    And the customer "{customerId}" balance should remain 2.00
    
    # Add more balance and try again
    And I add balance 10.00 to customer "{customerId}"
    And I initiate a stream delivery for customer "{customerId}" and stream "{streamId}"
    Then the stream delivery should be initiated successfully
    And the customer "{customerId}" balance should be 7.00
    
    # Complete and verify payment
    And I expire all stream deliveries
    And I get author payment report
    Then author "{authorId}" should have 1 completed streams
    And author "{authorId}" should have total payment 5.00

  Scenario: Multiple customers, multiple authors, complex workflow
    # Setup tenant
    Given a tenant with id "11111111-1111-1111-1111-111111111111"
    And I use tenant "11111111-1111-1111-1111-111111111111"
    
    # Create authors
    Given I create an author with name "Author A" and country "US"
    And I store the author id as "authorAId"
    And I create an author with name "Author B" and country "UK"
    And I store the author id as "authorBId"
    
    # Create streams
    And I create a stream with title "Song A1", author_id "{authorAId}", size_mb 5.0, duration_seconds 180, cost 1.00, and genre "Pop"
    And I store the stream id as "songA1Id"
    And I create a stream with title "Song A2", author_id "{authorAId}", size_mb 5.0, duration_seconds 180, cost 1.50, and genre "Pop"
    And I store the stream id as "songA2Id"
    And I create a stream with title "Song B1", author_id "{authorBId}", size_mb 5.0, duration_seconds 180, cost 2.00, and genre "Rock"
    And I store the stream id as "songB1Id"
    
    # Create customers
    And I create a customer with name "Customer 1" and email "customer1@example.com"
    And I store the customer id as "customer1Id"
    And I create a customer with name "Customer 2" and email "customer2@example.com"
    And I store the customer id as "customer2Id"
    And I create a customer with name "Customer 3" and email "customer3@example.com"
    And I store the customer id as "customer3Id"
    
    # Add balance
    And I add balance 100.00 to customer "{customer1Id}"
    And I add balance 100.00 to customer "{customer2Id}"
    And I add balance 100.00 to customer "{customer3Id}"
    
    # Create requests - various combinations
    And I create a stream request for customer "{customer1Id}" and stream "{songA1Id}" at "2026-04-26T10:00:00Z"
    And I create a stream request for customer "{customer1Id}" and stream "{songA2Id}" at "2026-04-26T10:01:00Z"
    And I create a stream request for customer "{customer1Id}" and stream "{songB1Id}" at "2026-04-26T10:02:00Z"
    And I create a stream request for customer "{customer2Id}" and stream "{songA1Id}" at "2026-04-26T10:03:00Z"
    And I create a stream request for customer "{customer2Id}" and stream "{songB1Id}" at "2026-04-26T10:04:00Z"
    And I create a stream request for customer "{customer3Id}" and stream "{songA2Id}" at "2026-04-26T10:05:00Z"
    
    # Approve all
    When I approve stream requests before "2026-04-26T12:00:00Z"
    Then the approval should report 6 approved
    
    # Initiate deliveries
    And I initiate a stream delivery for customer "{customer1Id}" and stream "{songA1Id}"
    And I initiate a stream delivery for customer "{customer1Id}" and stream "{songA2Id}"
    And I initiate a stream delivery for customer "{customer1Id}" and stream "{songB1Id}"
    And I initiate a stream delivery for customer "{customer2Id}" and stream "{songA1Id}"
    And I initiate a stream delivery for customer "{customer2Id}" and stream "{songB1Id}"
    And I initiate a stream delivery for customer "{customer3Id}" and stream "{songA2Id}"
    
    # Expire all
    And I expire all stream deliveries
    
    # Check payments
    When I get author payment report
    Then the report should show 2 authors
    And author "{authorAId}" should have 4 completed streams
    And author "{authorAId}" should have total payment 5.00
    And author "{authorBId}" should have 2 completed streams
    And author "{authorBId}" should have total payment 4.00
    And the grand total payment should be 9.00
