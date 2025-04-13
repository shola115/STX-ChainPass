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

;; Update Event Details
(define-public (update-event-details
  (ticket-id (string-ascii 100))
  (new-event-name (string-ascii 100))
  (new-event-date (string-ascii 50))
  (new-ticket-price uint)
)
  (let ((ticket-info (unwrap! (get-ticket-metadata ticket-id) ERR-TICKET-NOT-FOUND)))
    (begin
      ;; Ensure only contract owner can update
      (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-OWNER)

      ;; Prevent updates after tickets have been sold
      (asserts! (is-eq (get current-sales ticket-info) u0) ERR-TICKETS-ALREADY-SOLD)

      ;; Validate new inputs
      (asserts! (is-valid-event-name new-event-name) ERR-INVALID-INPUT)
      (asserts! (is-valid-event-date new-event-date) ERR-INVALID-INPUT)
      (asserts! (is-valid-ticket-price new-ticket-price) ERR-INVALID-INPUT)

      ;; Update ticket metadata
      (map-set ticket-metadata 
        {ticket-id: ticket-id}
        (merge ticket-info {
          event-name: new-event-name,
          event-date: new-event-date,
          ticket-price: new-ticket-price
        })
      )

      (ok true)
    )
  )
)

;; Purchase ticket
(define-public (purchase-ticket (ticket-id (string-ascii 100)))
  (let ((ticket-info (unwrap! (get-ticket-metadata ticket-id) ERR-TICKET-NOT-FOUND)))
    (begin
      ;; Check if ticket has not been cancelled
      (asserts! (not (get is-cancelled ticket-info)) (err u108))

      ;; Check if ticket sales haven't exceeded max capacity
      (asserts! 
        (< (get current-sales ticket-info) (get max-capacity ticket-info)) 
        ERR-CAPACITY-EXCEEDED
      )

      ;; Transfer ticket price (simplified - would integrate with STX transfer)
      (try! (stx-transfer? (get ticket-price ticket-info) tx-sender CONTRACT-OWNER))

      ;; Update ticket sales
      (map-set ticket-metadata 
        {ticket-id: ticket-id}
        (merge ticket-info {current-sales: (+ (get current-sales ticket-info) u1)})
      )

      ;; Record ticket holder
      (map-set event-ticket-holders 
        {ticket-id: ticket-id, ticket-owner: tx-sender} 
        true
      )

      ;; Mint ticket NFT to purchaser
      (nft-mint? codeentry-ticket ticket-id tx-sender)
    )
  )
)

;; Transfer ticket
(define-public (transfer-ticket 
  (ticket-id (string-ascii 100)) 
  (new-owner principal)
)
  (begin
    ;; Validate transfer recipient
    (asserts! (is-valid-principal new-owner) ERR-INVALID-TRANSFER-RECIPIENT)

    ;; Ensure only current ticket owner can transfer
    (asserts! 
      (is-eq tx-sender (unwrap! (nft-get-owner? codeentry-ticket ticket-id) ERR-TICKET-NOT-FOUND)) 
      ERR-UNAUTHORIZED-TRANSFER
    )

    ;; Transfer ticket ownership map
    (map-delete event-ticket-holders {ticket-id: ticket-id, ticket-owner: tx-sender})
    (map-set event-ticket-holders 
      {ticket-id: ticket-id, ticket-owner: new-owner} 
      true
    )

    ;; Transfer NFT
    (nft-transfer? codeentry-ticket ticket-id tx-sender new-owner)
  )
)

;; Cancel Event
(define-public (cancel-event (ticket-id (string-ascii 100)))
  (let ((ticket-info (unwrap! (get-ticket-metadata ticket-id) ERR-TICKET-NOT-FOUND)))
    (begin
      ;; Ensure only contract owner can cancel
      (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-OWNER)

      ;; Ensure event hasn't already been cancelled
      (asserts! (not (get is-cancelled ticket-info)) ERR-EVENT-ALREADY-CANCELLED)

      ;; Mark event as cancelled
      (map-set ticket-metadata 
        {ticket-id: ticket-id}
        (merge ticket-info {is-cancelled: true})
      )

      (ok true)
    )
  )
)

;; Refund Ticket
(define-public (refund-ticket (ticket-id (string-ascii 100)))
  (let (
    (ticket-info (unwrap! (get-ticket-metadata ticket-id) ERR-TICKET-NOT-FOUND))
    (ticket-owner (unwrap! (nft-get-owner? codeentry-ticket ticket-id) ERR-TICKET-NOT-FOUND))
  )
    (begin
      ;; Ensure event is cancelled
      (asserts! (get is-cancelled ticket-info) (err u109))

      ;; Ensure caller is ticket owner
      (asserts! (is-eq tx-sender ticket-owner) ERR-UNAUTHORIZED-TRANSFER)

      ;; Burn the ticket NFT
      (try! (nft-burn? codeentry-ticket ticket-id tx-sender))

      ;; Refund ticket price
      (try! (stx-transfer? (get ticket-price ticket-info) CONTRACT-OWNER tx-sender))

      ;; Remove ticket holder
      (map-delete event-ticket-holders 
        {ticket-id: ticket-id, ticket-owner: tx-sender}
      )

      (ok true)
    )
  )
)
