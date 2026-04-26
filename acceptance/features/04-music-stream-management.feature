Feature: Music Stream Management
  Music streams are musical pieces available for streaming, associated with authors

  Scenario: Create a music stream successfully
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    When I create a stream with the following details:
      | title            | Time                           |
      | author_id        | {authorId}                     |
      | size_mb          | 8.5                            |
      | duration_seconds | 295                            |
      | cost             | 0.99                           |
      | genre            | Soundtrack                     |
      | release_date     | 2010-07-13                     |
      | bitrate          | 320                            |
    Then the stream should be created successfully
    And the stream should have title "Time"
    And the stream should have author_id "{authorId}"
    And the stream should have cost 0.99
    And the stream should have an id
    And the stream should have a created_at timestamp

  Scenario: Create stream with minimum required fields
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    When I create a stream with title "Simple Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.50, and genre "Pop"
    Then the stream should be created successfully

  Scenario: Cannot create stream without title
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    When I create a stream without title for author "{authorId}"
    Then the request should fail with status 400
    And the error should be "VALIDATION_ERROR"

  Scenario: Cannot create stream without author_id
    When I create a stream with title "Test Song" without author_id
    Then the request should fail with status 400
    And the error should be "VALIDATION_ERROR"

  Scenario: Cannot create stream with non-existent author
    When I create a stream with title "Test Song", author_id "99999999-9999-9999-9999-999999999999", size_mb 5.0, duration_seconds 180, cost 0.50, and genre "Pop"
    Then the request should fail with status 404
    And the error should be "AUTHOR_NOT_FOUND"

  Scenario: Cannot create stream with negative cost
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    When I create a stream with title "Test Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost -1.00, and genre "Pop"
    Then the request should fail with status 400
    And the error should be "VALIDATION_ERROR"

  Scenario: Create stream with zero cost
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    When I create a stream with title "Free Song", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.00, and genre "Pop"
    Then the stream should be created successfully
    And the stream should have cost 0.00

  Scenario: Create multiple streams for same author
    Given I create an author with name "Test Author" and country "US"
    And I store the author id as "authorId"
    When I create a stream with title "Song 1", author_id "{authorId}", size_mb 5.0, duration_seconds 180, cost 0.99, and genre "Pop"
    And I create a stream with title "Song 2", author_id "{authorId}", size_mb 4.5, duration_seconds 200, cost 1.29, and genre "Rock"
    Then both streams should be created successfully
