# User Microservice (Ritmistas): Ecosystem Provider Standard

## 1. Role in Ecosystem
Ritmistas serves as the **Identity Provider (IdP)** and **Points Ledger** for all B10 services. To support the "Universal User Integration Standard", the User Service must expose and emit data in a specific format.

## 2. API Output Requirements
All user-related endpoints (e.g., `/users/{id}`, `GET /auth/me`) must return fields using standardized naming.

| Field Name | Ecosystem Consumes | Alignment |
| :--- | :--- | :--- |
| `user_id` | Unique UUID | Must be the primary token `sub`. |
| `username` | String (Nickname) | The distinctive nickname (lowercase, no spaces). |
| `full_name` | String | Junction of `first_name` + `last_name`. |
| `photo_url` | String | Full public URL to the profile image. |
| `email` | String | Primary validated email. |

## 3. Event Driven Consistency
When a user profile is updated in Ritmistas, it MUST emit an event (via Webhook, BullMQ, or NATS) with the standardized payload:
```json
{
  "event": "user.profile_updated",
  "data": {
    "user_id": "uuid-v4",
    "full_name": "New Name",
    "photo_url": "https://...",
    "email": "user@example.com"
  }
}
```

## 4. Database Integrity
Ensure that any internal renames (e.g., `id` to `user_id`) do not break existing JWT issuance but align with the ecosystem's table-level standard.

## 5. Ecosystem RBAC Mapping
As the identity provider, Ritmistas ensures the base roles align with the ecosystem standard: `admin`, `leader`, `sub-leader`, `member`, `viewer`. These are now emitted in the JWT as `ecosystem_role` for consumption by all services.
