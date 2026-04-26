# Acceptance Tests - Implementation Notes

## Missing Step Definitions

Some step definitions reference API endpoints that would be needed for full validation but aren't specified in the OpenAPI spec:

- `GET /customers/{id}` - needed to verify balance after operations
- `GET /stream-requests/{id}` - needed to verify request status after approval
- `GET /stream-deliveries/{id}` - needed to verify delivery status after expiration

These steps currently contain placeholder logic or skip validation. When implementing the API, consider adding these GET endpoints for better testability.

## Step Definition Improvements Needed

1. **Better response tracking**: Currently only tracks the last response. For scenarios testing multiple operations, we should track responses in an array.

2. **GET endpoints**: Several "Then" steps assume we can fetch entities to verify their state. These need GET endpoints added to the API.

3. **Timing control**: Steps like "the stream delivery expires at {string}" store a timestamp but don't actually control when the delivery expires. The API would need to either:
   - Accept an `expires_at` parameter in the initiate delivery request (for testing)
   - Use very short expiration times (a few seconds as mentioned in domain.md)

4. **Complex scenario helpers**: Steps like "I create 3 approved stream requests" are implemented but could be more robust with better tracking of which specific requests were created.

## Configuration Notes

The `playwright.config.ts` is configured for API testing but uses a Chrome browser context. For pure API testing without UI, you might want to:
- Remove the browser requirement
- Use only `@playwright/test`'s `request` context
- Adjust the project configuration

## Test Data Management

Currently, tests create fresh data for each scenario. Consider:
- Adding database cleanup hooks (if needed)
- Using test-specific tenant IDs that can be easily cleaned up
- Implementing a "cleanup" background step if the API supports bulk deletion

## Running Against Different Environments

To run tests against different environments:

```bash
# Development
npm test

# Staging
API_BASE_URL=https://staging-api.example.com npm test

# Production (not recommended for acceptance tests that create data)
API_BASE_URL=https://api.example.com npm test
```

## Future Enhancements

1. **Parallel execution**: Tests could be made more parallel-safe by using unique tenant IDs per test file or scenario
2. **Performance testing**: Current scenarios focus on functionality, not performance
3. **Negative path coverage**: Add more error scenarios (malformed JSON, invalid UUIDs, etc.)
4. **Data-driven tests**: Use Scenario Outlines for testing multiple data combinations
5. **Hooks**: Add Before/After hooks for test data setup and cleanup
