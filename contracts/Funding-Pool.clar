;; Decentralized Research Funding Pool Contract
;; Scientists submit proposals; token holders vote on who gets grants

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-VOTED (err u102))
(define-constant ERR-VOTING-ENDED (err u103))
(define-constant ERR-INSUFFICIENT-BALANCE (err u104))
(define-constant ERR-PROPOSAL-ALREADY-EXECUTED (err u105))
(define-constant ERR-INVALID-INPUT (err u106))

;; Data Variables
(define-data-var next-proposal-id uint u1)
(define-data-var voting-period uint u1440) ;; blocks (~10 days)

;; Data Maps
(define-map proposals
  { proposal-id: uint }
  {
    scientist: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    funding-amount: uint,
    votes-for: uint,
    votes-against: uint,
    created-at: uint,
    executed: bool
  }
)

(define-map votes
  { proposal-id: uint, voter: principal }
  { vote: bool, amount: uint }
)

(define-map token-balances
  { holder: principal }
  { balance: uint }
)

;; Read-only functions
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals { proposal-id: proposal-id })
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes { proposal-id: proposal-id, voter: voter })
)

(define-read-only (get-token-balance (holder principal))
  (default-to u0 (get balance (map-get? token-balances { holder: holder })))
)

(define-read-only (get-next-proposal-id)
  (var-get next-proposal-id)
)

(define-read-only (get-voting-period)
  (var-get voting-period)
)

;; Public functions

;; Submit a research proposal
(define-public (submit-proposal (title (string-ascii 100)) (description (string-ascii 500)) (funding-amount uint))
  (let
    (
      (proposal-id (var-get next-proposal-id))
    )
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)
    (asserts! (> (len description) u0) ERR-INVALID-INPUT)
    (asserts! (> funding-amount u0) ERR-INVALID-INPUT)

    (map-set proposals
      { proposal-id: proposal-id }
      {
        scientist: tx-sender,
        title: title,
        description: description,
        funding-amount: funding-amount,
        votes-for: u0,
        votes-against: u0,
        created-at: block-height,
        executed: false
      }
    )
    (var-set next-proposal-id (+ proposal-id u1))
    (ok proposal-id)
  )
)

;; Vote on a proposal (true for yes, false for no)
(define-public (vote-on-proposal (proposal-id uint) (vote bool))
  (let
    (
      (voter-balance (get-token-balance tx-sender))
      (proposal (unwrap! (get-proposal proposal-id) ERR-PROPOSAL-NOT-FOUND))
      (existing-vote (get-vote proposal-id tx-sender))
    )
    (asserts! (> voter-balance u0) ERR-INSUFFICIENT-BALANCE)
    (asserts! (is-none existing-vote) ERR-ALREADY-VOTED)
    (asserts! (<= (+ (get created-at proposal) (var-get voting-period)) block-height) ERR-VOTING-ENDED)

    (map-set votes
      { proposal-id: proposal-id, voter: tx-sender }
      { vote: vote, amount: voter-balance }
    )

    (if vote
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal { votes-for: (+ (get votes-for proposal) voter-balance) })
      )
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal { votes-against: (+ (get votes-against proposal) voter-balance) })
      )
    )
    (ok true)
  )
)

;; Execute approved proposal (distribute grant)
(define-public (execute-proposal (proposal-id uint))
  (let
    (
      (proposal (unwrap! (get-proposal proposal-id) ERR-PROPOSAL-NOT-FOUND))
    )
    (asserts! (not (get executed proposal)) ERR-PROPOSAL-ALREADY-EXECUTED)
    (asserts! (> (+ (get created-at proposal) (var-get voting-period)) block-height) ERR-VOTING-ENDED)
    (asserts! (> (get votes-for proposal) (get votes-against proposal)) ERR-NOT-AUTHORIZED)

    (try! (stx-transfer? (get funding-amount proposal) (as-contract tx-sender) (get scientist proposal)))

    (map-set proposals
      { proposal-id: proposal-id }
      (merge proposal { executed: true })
    )
    (ok true)
  )
)

;; Mint tokens to participants (simplified - in practice would be more sophisticated)
(define-public (mint-tokens (recipient principal) (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> amount u0) ERR-INVALID-INPUT)
    (asserts! (not (is-eq recipient (as-contract tx-sender))) ERR-INVALID-INPUT)
    (map-set token-balances
      { holder: recipient }
      { balance: (+ (get-token-balance recipient) amount) }
    )
    (ok true)
  )
)

;; Deposit STX to fund the pool
(define-public (deposit-funds (amount uint))
  (begin
    (asserts! (> amount u0) ERR-INVALID-INPUT)
    (stx-transfer? amount tx-sender (as-contract tx-sender))
  )
)

;; Get contract STX balance
(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender))
)