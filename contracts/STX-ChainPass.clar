;; The STX-ChainPass Ticketing smart contract is a decentralized ticketing platform built on the Stacks blockchain using the Clarity smart contract language


(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-OWNER (err u100))
(define-constant ERR-TICKET-ALREADY-MINTED (err u101))
(define-constant ERR-TICKET-NOT-FOUND (err u102))
(define-constant ERR-UNAUTHORIZED-TRANSFER (err u103))
(define-constant ERR-INVALID-INPUT (err u104))
(define-constant ERR-CAPACITY-EXCEEDED (err u105))
(define-constant ERR-EVENT-ALREADY-CANCELLED (err u106))
(define-constant ERR-REFUND-FAILED (err u107))
(define-constant ERR-TICKETS-ALREADY-SOLD (err u108))
(define-constant ERR-INVALID-TRANSFER-RECIPIENT (err u109))


;; Map
(define-map ticket-metadata 
  {ticket-id: (string-ascii 100)} 
  {
    event-name: (string-ascii 100),
    event-date: (string-ascii 50),
    ticket-price: uint,
    max-capacity: uint,
    current-sales: uint,
    is-cancelled: bool
  }
)


;; Tracks ticket holders for each event
(define-map event-ticket-holders 
  {ticket-id: (string-ascii 100), ticket-owner: principal} 
  bool
)


;; Private functions
(define-private (is-valid-event-name (name (string-ascii 100)))
  (and 
    (> (len name) u0) 
    (<= (len name) u100)
  )
)

(define-private (is-valid-event-date (date (string-ascii 50)))
  (and 
    (> (len date) u0) 
    (<= (len date) u50)
  )
)

(define-private (is-valid-ticket-price (price uint))
  (> price u0)
)

(define-private (is-valid-max-capacity (capacity uint))
  (> capacity u0)
)

;; Principal Validation Function
(define-private (is-valid-principal (addr principal))
  (not (is-eq addr CONTRACT-OWNER))
)


;; Read-only functions
(define-read-only (get-ticket-owner (ticket-id (string-ascii 100)))
  (nft-get-owner? codeentry-ticket ticket-id)
)

(define-read-only (get-ticket-metadata (ticket-id (string-ascii 100)))
  (map-get? ticket-metadata {ticket-id: ticket-id})
)

;; Public Functions
;; Mint new event ticket
(define-public (mint-ticket 
  (ticket-id (string-ascii 100))
  (event-name (string-ascii 100))
  (event-date (string-ascii 50))
  (ticket-price uint)
  (max-capacity uint)
)
  (begin
    ;; Validate inputs
    (asserts! (is-valid-event-name event-name) ERR-INVALID-INPUT)
    (asserts! (is-valid-event-date event-date) ERR-INVALID-INPUT)
    (asserts! (is-valid-ticket-price ticket-price) ERR-INVALID-INPUT)
    (asserts! (is-valid-max-capacity max-capacity) ERR-INVALID-INPUT)

    ;; Ensure ticket hasn't been minted before
    (asserts! (is-none (get-ticket-metadata ticket-id)) ERR-TICKET-ALREADY-MINTED)

    ;; Create ticket metadata
    (map-set ticket-metadata 
      {ticket-id: ticket-id}
      {
        event-name: event-name,
        event-date: event-date,
        ticket-price: ticket-price,
        max-capacity: max-capacity,
        current-sales: u0,
        is-cancelled: false
      }
    )

    ;; Mint NFT to contract owner
    (nft-mint? codeentry-ticket ticket-id CONTRACT-OWNER)
  )
)
