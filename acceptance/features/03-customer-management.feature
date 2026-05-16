Feature: Customer Management
  Customers can request and consume music streams. They have an active/inactive status and a balance.

  Scenario: Create a new customer successfully
    When I create a customer with name "Jane Doe" and email "jane@example.com"
    Then the customer should be created successfully
    And the customer should have name "Jane Doe"
    And the customer should have email "jane@example.com"
    And the customer should have status "active"
    And the customer should have balance 0
    And the customer should have an id
    And the customer should have created_at and updated_at timestamps

  Scenario: Cannot create customer without name
    When I create a customer with email "test@example.com" but no name
    Then the request should fail with status 400
    And the error should be "VALIDATION_ERROR"

  Scenario: Cannot create customer without email
    When I create a customer with name "Test User" but no email
    Then the request should fail with status 400
    And the error should be "VALIDATION_ERROR"

  Scenario: Activate a customer
    Given I create a customer with name "Test User" and email "test@example.com"
    And I store the customer id as "customerId"
    And I deactivate customer "{customerId}"
    When I activate customer "{customerId}"
    Then the customer should be activated successfully
    And the customer should have status "active"

  Scenario: Activate an already active customer is idempotent
    Given I create a customer with name "Test User" and email "test@example.com"
    And I store the customer id as "customerId"
    When I activate customer "{customerId}"
    Then the customer should be activated successfully
    And the customer should have status "active"

  Scenario: Deactivate a customer
    Given I create a customer with name "Test User" and email "test@example.com"
    And I store the customer id as "customerId"
    When I deactivate customer "{customerId}"
    Then the customer should be deactivated successfully
    And the customer should have status "inactive"

  Scenario: Deactivate an already inactive customer is idempotent
    Given I create a customer with name "Test User" and email "test@example.com"
    And I store the customer id as "customerId"
    And I deactivate customer "{customerId}"
    When I deactivate customer "{customerId}"
    Then the customer should be deactivated successfully
    And the customer should have status "inactive"

  Scenario: Add balance to customer account
    Given I create a customer with name "Test User" and email "test@example.com"
    And I store the customer id as "customerId"
    When I add balance 50.00 to customer "{customerId}"
    Then the balance should be added successfully
    And the customer should have balance 50.00

  Scenario: Add balance multiple times
    Given I create a customer with name "Test User" and email "test@example.com"
    And I store the customer id as "customerId"
    When I add balance 25.00 to customer "{customerId}"
    And I add balance 30.00 to customer "{customerId}"
    Then the customer should have balance 55.00

  Scenario: Cannot add negative balance
    Given I create a customer with name "Test User" and email "test@example.com"
    And I store the customer id as "customerId"
    When I add balance -10.00 to customer "{customerId}"
    Then the request should fail with status 400
    And the error should be "VALIDATION_ERROR"

  Scenario: Cannot add zero balance
    Given I create a customer with name "Test User" and email "test@example.com"
    And I store the customer id as "customerId"
    When I add balance 0 to customer "{customerId}"
    Then the request should fail with status 400
    And the error should be "VALIDATION_ERROR"

  Scenario: Cannot operate on non-existent customer
    When I activate customer "99999999-9999-9999-9999-999999999999"
    Then the request should fail with status 404
    And the error should be "CUSTOMER_NOT_FOUND"
