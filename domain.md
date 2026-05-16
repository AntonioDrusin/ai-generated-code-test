# Music Stream Order & Delivery System - Domain Model

## Overview
A system for managing music stream orders and deliveries, tracking customer requests, stream consumption, and author payments. The system is multi-tenant. Every entity belongs to a tenant, and all API operations are scoped to a tenant via a required `X-Tenant-ID` header.

## Multi-Tenancy

All data is scoped to a tenant. Every aggregate includes a `tenant_id` property, and every API request requires an `X-Tenant-ID` header. Queries and mutations only operate on data belonging to the specified tenant.

**Rules:**
- `tenant_id` (UUID) is present on every table/aggregate
- `X-Tenant-ID` header is required on every API request
- All queries filter by `tenant_id`
- Cross-tenant data access is not permitted

## Aggregates

### Customer
Represents a user who can request and consume music streams.

**Properties:**
- `id` (UUID/GUID)
- `tenant_id` (UUID) - tenant scope
- `name` (string)
- `email` (string)
- `status` (enum: `active`, `inactive`)
- `created_at` (timestamp)
- `updated_at` (timestamp)
- `balance` (decimal)

**Business Rules:**
- Only active customers can have their stream requests approved
- Inactive customers' stream requests are flagged as `denied`
- balance is updated when a customer initiates a stream delivery, if not enough money, delivery is denied balance is not changed.

---

### Author
Represents a music creator who publishes streams and receives payments.

**Properties:**
- `id` (UUID/GUID)
- `tenant_id` (UUID) - tenant scope
- `name` (string)
- `country` (string) - for future tax calculations
- `created_at` (timestamp)

**Business Rules:**
- Authors receive payment based on completed stream deliveries of their music

---

### Music_Stream
Represents a musical piece available for streaming.

**Properties:**
- `id` (UUID/GUID)
- `tenant_id` (UUID) - tenant scope
- `title` (string)
- `author_id` (UUID/GUID) - reference to Author
- `size_mb` (decimal) - size in megabytes
- `duration_seconds` (integer) - length in seconds
- `cost` (decimal) - payment to author per completed stream
- `genre` (string)
- `release_date` (date)
- `bitrate` (integer) - audio quality in kbps
- `created_at` (timestamp)

**Business Rules:**
- Must be associated with an existing author
- Cost determines author payment per completed delivery

---

### Stream_Request
Represents a customer's request to stream a music piece. These requests are free to create.

**Properties:**
- `id` (UUID/GUID)
- `tenant_id` (UUID) - tenant scope
- `customer_id` (UUID/GUID) - reference to Customer
- `music_stream_id` (UUID/GUID) - reference to Music_Stream
- `status` (enum: `pending`, `approved`, `denied`)
- `requested_at` (timestamp)
- `processed_at` (timestamp, nullable)

**Business Rules:**
- Created by customers - no cost to request
- Initially created with status `pending`
- Approved only if customer is `active` at approval time
- Denied if customer is `inactive` at approval time
- Approval happens in batch by processing date
- Stream requests can only reference customers and music streams within the same tenant

---

### Stream_Delivery
Represents an active or completed stream session. Only created when a stream is actually initiated.

**Properties:**
- `id` (UUID/GUID)
- `tenant_id` (UUID) - tenant scope
- `stream_request_id` (UUID/GUID) - reference to Stream_Request
- `customer_id` (UUID/GUID) - reference to Customer
- `music_stream_id` (UUID/GUID) - reference to Music_Stream
- `status` (enum: `active`, `done`)
- `stream_url` (string) - fake URL for testing
- `initiated_at` (timestamp)
- `expires_at` (timestamp) - short expiration for testing (few seconds)
- `completed_at` (timestamp, nullable)

**Business Rules:**
- Only created when customer initiates/accesses an approved stream request
- Starts with status `active`
- Transitions to `done` when expired or manually completed
- Only `done` deliveries count toward author payments
- Expiration time set to a few seconds for performance testing
- Deliveries are scoped to tenant; cross-tenant delivery is not permitted

---

## API Operations

> All API endpoints require an `X-Tenant-ID` header (UUID). All operations are scoped to the specified tenant.

### Author Management
- **Create Author** `POST /authors`: Register a new author with name and country

### Customer Management
- **Create Customer** `POST /customers`: Register a new customer (default status: `active`, balance: 0)
- **Deactivate Customer** `POST /customers/{id}/deactivate`: Set customer status to `inactive` (idempotent - succeeds even if already inactive)
- **Activate Customer** `POST /customers/{id}/activate`: Set customer status to `active` (idempotent - succeeds even if already active)
- **Add Balance** `POST /customers/{id}/balance`: Add funds to customer balance

### Music Stream Management
- **Create Stream** `POST /streams`: Add a new music stream to the catalog

### Stream Request & Delivery
- **Request Stream** `POST /stream-requests`: Customer creates a stream_request (status: `pending`). The `requested_at` datetime is provided in the body for testing purposes.
- **Approve Stream Requests** `POST /stream-requests/approve`: Batch approve all `pending` requests with `requested_at` on or before a given datetime
  - Approved if customer is `active` → status: `approved`
  - Denied if customer is `inactive` → status: `denied`
- **Initiate Stream Delivery** `POST /stream-deliveries`: Customer passes `customer_id` and `music_stream_id`. System finds the oldest `approved` stream request for that combination.
  - If no approved request exists → `409 NO_APPROVED_REQUEST`
  - If customer is inactive → `409 CUSTOMER_INACTIVE`
  - If customer balance < stream cost → `409 INSUFFICIENT_BALANCE` (balance unchanged)
  - Otherwise: creates `stream_delivery` (status: `active`), deducts cost from balance, returns fake stream URL with short expiration
- **Expire Stream Deliveries** `POST /stream-deliveries/expire`: Transition all `active` deliveries whose `expires_at` is on or before the given datetime to status `done`

### Reporting
- **Get Author Payment Amount** `GET /reports/author-payments`: Returns payment summary for all authors
  - Calculates: SUM(music_stream.cost) for all stream_deliveries with status `done`
  - Returns table format:
    ```
    author_id | author_name | country | total_completed_streams | total_payment_amount
    ```
  - Includes `grand_total_amount` across all authors

---

## Workflows

### 1. Customer Stream Consumption Flow
```
0. Tenant exists (all subsequent operations use X-Tenant-ID header)
1. Author created
2. Music stream created (associated with author)
3. Customer created (status: active, balance: 0)
4. Customer balance topped up
5. Customer requests stream → stream_request (status: pending, requested_at provided)
6. System approves stream requests (batch, by datetime cutoff)
   - If customer active → stream_request (status: approved)
   - If customer inactive → stream_request (status: denied)
7. Customer initiates stream delivery (customer_id + music_stream_id)
   - System finds oldest approved request for the combination
   - Checks customer active, checks balance >= cost
   - Deducts cost from balance
   - Creates stream_delivery (status: active)
   - Returns fake stream URL with short expiration
8. System expires deliveries (by datetime cutoff) → stream_delivery (status: done)
9. Author payment calculated from completed deliveries
```

### 2. Author Payment Calculation
```
For each author:
  - Find all music_streams by author_id
  - Find all stream_deliveries for those streams with status = 'done'
  - Calculate: COUNT(deliveries) × music_stream.cost
  - Return aggregated totals per author
```

---

## Key Relationships

- **Author** ← (1:N) → **Music_Stream**
- **Customer** ← (1:N) → **Stream_Request**
- **Music_Stream** ← (1:N) → **Stream_Request**
- **Stream_Request** ← (1:1) → **Stream_Delivery** (optional, only if initiated)
- **Customer** ← (1:N) → **Stream_Delivery**
- **Music_Stream** ← (1:N) → **Stream_Delivery**
- All relationships are scoped within a single tenant

---

## Notes for Performance Testing

- Stream requests are free (no payment processing)
- Stream deliveries have short expiration times (few seconds)
- No full CRUD operations implemented - focused on specific workflows
- Batch approval processing for stream requests
- Payment calculations aggregate completed deliveries
- Multi-tenant isolation ensures no cross-tenant data leakage