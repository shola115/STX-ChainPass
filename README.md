# STX-ChainPass Ticketing Smart Contract

## Overview

The `STX-ChainPass` smart contract is a decentralized ticketing platform built on the **Stacks blockchain** using the Clarity smart contract language. This contract allows event organizers (contract owner) to mint event tickets as NFTs, manage event metadata, facilitate ticket sales and transfers, and offer refunds for cancelled events.

---

## 🛠️ Features

- ✅ Mint NFTs representing event tickets  
- 📆 Store event metadata (name, date, price, capacity)  
- 💳 Allow users to purchase tickets with STX  
- 🔄 Transfer tickets between users  
- ❌ Cancel events and enable refunds  
- 🛡️ Input validation and error handling  

---

## 🔐 Contract Constants

| Constant | Description |
|---------|-------------|
| `CONTRACT-OWNER` | Set to `tx-sender` at contract deployment |
| `ERR-NOT-OWNER` | `err u100` – Only the contract owner can call this function |
| `ERR-TICKET-ALREADY-MINTED` | `err u101` – Ticket with this ID already exists |
| `ERR-TICKET-NOT-FOUND` | `err u102` – Ticket ID does not exist |
| `ERR-UNAUTHORIZED-TRANSFER` | `err u103` – Unauthorized transfer attempt |
| `ERR-INVALID-INPUT` | `err u104` – Input validation failed |
| `ERR-CAPACITY-EXCEEDED` | `err u105` – No more tickets available |
| `ERR-EVENT-ALREADY-CANCELLED` | `err u106` – Event already cancelled |
| `ERR-REFUND-FAILED` | `err u107` – STX refund failed |
| `ERR-TICKETS-ALREADY-SOLD` | `err u108` – Cannot update event after sales |
| `ERR-INVALID-TRANSFER-RECIPIENT` | `err u109` – Transfer recipient is invalid |

---

## 📂 Data Structures

### Maps

- `ticket-metadata`  
  Stores metadata for each ticket.
  ```clojure
  {ticket-id: string} => {
    event-name: string,
    event-date: string,
    ticket-price: uint,
    max-capacity: uint,
    current-sales: uint,
    is-cancelled: bool
  }
  ```

- `event-ticket-holders`  
  Tracks which user holds which ticket.
  ```clojure
  {ticket-id: string, ticket-owner: principal} => bool
  ```

---

## 📋 Functions

### ✅ Public Functions

#### `mint-ticket`
Mint a new ticket (only once per ticket ID).
```clojure
(mint-ticket ticket-id event-name event-date ticket-price max-capacity)
```

#### `update-event-details`
Update ticket metadata (only before any sales).
```clojure
(update-event-details ticket-id new-event-name new-event-date new-ticket-price)
```

#### `purchase-ticket`
Purchase a ticket. Transfers STX and assigns NFT.
```clojure
(purchase-ticket ticket-id)
```

#### `transfer-ticket`
Transfer a ticket to another user.
```clojure
(transfer-ticket ticket-id new-owner)
```

#### `cancel-event`
Cancel an event (owner only).
```clojure
(cancel-event ticket-id)
```

#### `refund-ticket`
Refund a ticket after event is cancelled.
```clojure
(refund-ticket ticket-id)
```

---

### 📖 Read-Only Functions

#### `get-ticket-owner`
Fetch the NFT owner of a ticket.
```clojure
(get-ticket-owner ticket-id)
```

#### `get-ticket-metadata`
Fetch metadata for a specific ticket.
```clojure
(get-ticket-metadata ticket-id)
```

---

### 🔒 Private Functions

- `is-valid-event-name` – Validates event name length
- `is-valid-event-date` – Validates date length
- `is-valid-ticket-price` – Checks if price > 0
- `is-valid-max-capacity` – Checks if capacity > 0
- `is-valid-principal` – Prevents contract owner from being recipient in transfer

---

## 🔄 NFT Integration

- NFT minting handled using `nft-mint?`
- Transfer with `nft-transfer?`
- Burn using `nft-burn?` in refunds

_Note: NFT token name used is assumed to be `codeentry-ticket`. Ensure to define it or import correctly in deployment._

---