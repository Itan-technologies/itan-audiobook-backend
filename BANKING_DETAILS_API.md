# Banking Details API Documentation

**Base URL:** `/api/v1/author/banking_details`  
**Authentication:** Session-based (author login required)

---

## 1. GET /banks

**Get list of available banks**

```http
GET /api/v1/author/banking_details/banks
```

**Response:**

```json
{
  "banks": [
    {
      "name": "First Bank of Nigeria",
      "code": "011"
    },
    {
      "name": "Access Bank",
      "code": "044"
    }
  ]
}
```

---

## 2. POST /verify

**Account verification (works for both new and saved details)**

```http
POST /api/v1/author/banking_details/verify
Content-Type: application/json

// Option 1: Verify new account details (for UI feedback)
{
  "bank_code": "011",
  "account_number": "3219076864"
}

// Option 2: Verify saved banking details (send empty body)
{}
```

**Purpose:**

- **With params:** Verify new account for UI feedback (doesn't save)
- **Without params:** Verify existing saved banking details

**Success Response:**

```json
{
  "success": true,
  "account_name": "JOHN DOE",
  "message": "Account verified successfully"
}
```

**Error Response:**

```json
{
  "success": false,
  "error": "Could not resolve account name"
}
```

---

## 3. PUT /

**Save banking details permanently (WITH verification)**

```http
PUT /api/v1/author/banking_details
Content-Type: application/json

{
  "banking_detail": {
    "bank_name": "First Bank of Nigeria",
    "bank_code": "011",
    "account_number": "3219076864",
    "account_name": "John Doe",
    "currency": "NGN"
  }
}
```

**Purpose:** Permanently save banking details to database after verifying with bank and creating Paystack recipient for payments.

**Success Response:**

```json
{
  "success": true,
  "message": "Banking details verified and saved successfully",
  "data": {
    "id": 123,
    "bank_name": "First Bank of Nigeria",
    "account_number": "XXXX6864",
    "resolved_account_name": "JOHN DOE",
    "verified_at": "2025-07-15T16:30:00.000Z"
  }
}
```

**Error Response:**

```json
{
  "success": false,
  "message": "Account verification failed",
  "errors": ["Account number verification failed"]
}
```

---

## 4. GET /

**Get current banking details**

```http
GET /api/v1/author/banking_details
```

**Response:**

```json
{
  "id": 123,
  "bank_name": "First Bank of Nigeria",
  "account_number": "XXXX6864",
  "account_name": "John Doe",
  "verified_at": "2025-07-15T16:30:00.000Z"
}
```

---

## Frontend Integration

```javascript
// Get banks
const banks = await fetch("/api/v1/author/banking_details/banks").then((r) =>
  r.json()
);

// Verify account (real-time validation)
const verification = await fetch("/api/v1/author/banking_details/verify", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ bank_code: "011", account_number: "3219076864" }),
}).then((r) => r.json());

// Save banking details
const result = await fetch("/api/v1/author/banking_details", {
  method: "PUT",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    banking_detail: {
      bank_name: "First Bank",
      bank_code: "011",
      account_number: "3219076864",
      account_name: "John Doe",
    },
  }),
}).then((r) => r.json());
```
