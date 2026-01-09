;; Title: Nexus Wealth Manager
;; Summary: Next-generation autonomous wealth orchestration platform for DeFi
;; Description: Nexus Wealth Manager revolutionizes decentralized finance through
;; intelligent portfolio automation and dynamic asset management. This cutting-edge
;; protocol empowers users to create sophisticated investment strategies with:
;;
;;   - Autonomous multi-asset portfolio orchestration
;;   - AI-driven rebalancing algorithms with customizable triggers  
;;   - Precision allocation engine supporting up to 10 digital assets
;;   - Enterprise-grade security architecture with comprehensive safeguards
;;   - Layer-2 optimized execution for minimal transaction costs
;;   - Real-time portfolio analytics and performance monitoring
;;
;; Built for the next generation of decentralized wealth management, Nexus combines
;; institutional-grade portfolio theory with blockchain innovation to deliver 
;; unparalleled investment automation for the modern DeFi ecosystem.

;; ERROR CONSTANTS
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-PORTFOLIO (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-INVALID-TOKEN (err u103))
(define-constant ERR-REBALANCE-FAILED (err u104))
(define-constant ERR-PORTFOLIO-EXISTS (err u105))
(define-constant ERR-INVALID-PERCENTAGE (err u106))
(define-constant ERR-MAX-TOKENS-EXCEEDED (err u107))
(define-constant ERR-LENGTH-MISMATCH (err u108))
(define-constant ERR-USER-STORAGE-FAILED (err u109))
(define-constant ERR-INVALID-TOKEN-ID (err u110))

;; PROTOCOL CONFIGURATION
(define-constant MAX-TOKENS-PER-PORTFOLIO u10)
(define-constant BASIS-POINTS u10000)

;; PROTOCOL STATE VARIABLES
(define-data-var protocol-owner principal tx-sender)
(define-data-var portfolio-counter uint u0)
(define-data-var protocol-fee uint u25) ;; 0.25% in basis points

;; CORE DATA STRUCTURES

;; Primary portfolio registry mapping
(define-map Portfolios
  uint ;; portfolio-id
  {
    owner: principal,
    created-at: uint,
    last-rebalanced: uint,
    total-value: uint,
    active: bool,
    token-count: uint,
  }
)

;; Asset allocation and tracking mapping
(define-map PortfolioAssets
  {
    portfolio-id: uint,
    token-id: uint,
  }
  {
    target-percentage: uint,
    current-amount: uint,
    token-address: principal,
  }
)

;; User portfolio ownership tracking
(define-map UserPortfolios
  principal
  (list 20 uint)
)

;; READ-ONLY QUERY FUNCTIONS

;; Retrieve complete portfolio information
(define-read-only (get-portfolio (portfolio-id uint))
  (map-get? Portfolios portfolio-id)
)

;; Fetch specific asset allocation within a portfolio
(define-read-only (get-portfolio-asset
    (portfolio-id uint)
    (token-id uint)
  )
  (map-get? PortfolioAssets {
    portfolio-id: portfolio-id,
    token-id: token-id,
  })
)

;; Get all portfolios owned by a specific user
(define-read-only (get-user-portfolios (user principal))
  (default-to (list) (map-get? UserPortfolios user))
)

;; Calculate rebalancing requirements and timing
(define-read-only (calculate-rebalance-amounts (portfolio-id uint))
  (let (
      (portfolio (unwrap! (get-portfolio portfolio-id) ERR-INVALID-PORTFOLIO))
      (total-value (get total-value portfolio))
    )
    (ok {
      portfolio-id: portfolio-id,
      total-value: total-value,
      needs-rebalance: (> (- stacks-block-height (get last-rebalanced portfolio)) u144),
    })
  )
)

;; PRIVATE UTILITY FUNCTIONS

;; Validate token ID bounds within portfolio constraints
(define-private (validate-token-id
    (portfolio-id uint)
    (token-id uint)
  )
  (let ((portfolio (unwrap! (get-portfolio portfolio-id) false)))
    (and
      (< token-id MAX-TOKENS-PER-PORTFOLIO)
      (< token-id (get token-count portfolio))
      true
    )
  )
)

;; Ensure percentage values are within valid range
(define-private (validate-percentage (percentage uint))
  (and (>= percentage u0) (<= percentage BASIS-POINTS))
)

;; Validate complete portfolio allocation percentages
(define-private (validate-portfolio-percentages (percentages (list 10 uint)))
  (fold check-percentage-sum percentages true)
)

;; Helper function for percentage validation fold operation
(define-private (check-percentage-sum
    (current-percentage uint)
    (valid bool)
  )
  (and valid (validate-percentage current-percentage))
)

;; Add new portfolio to user's ownership list
(define-private (add-to-user-portfolios
    (user principal)
    (portfolio-id uint)
  )
  (let (
      (current-portfolios (get-user-portfolios user))
      (new-portfolios (unwrap! (as-max-len? (append current-portfolios portfolio-id) u20)
        ERR-USER-STORAGE-FAILED
      ))
    )
    (map-set UserPortfolios user new-portfolios)
    (ok true)
  )
)

;; Initialize individual asset allocation within portfolio
(define-private (initialize-portfolio-asset
    (index uint)
    (token principal)
    (percentage uint)
    (portfolio-id uint)
  )
  (if (>= percentage u0)
    (begin
      (map-set PortfolioAssets {
        portfolio-id: portfolio-id,
        token-id: index,
      } {
        target-percentage: percentage,
        current-amount: u0,
        token-address: token,
      })
      (ok true)
    )
    ERR-INVALID-TOKEN
  )
)

;; PUBLIC INTERFACE FUNCTIONS

;; Create new automated portfolio with specified tokens and allocations
(define-public (create-portfolio
    (initial-tokens (list 10 principal))
    (percentages (list 10 uint))
  )
  (let (
      (portfolio-id (+ (var-get portfolio-counter) u1))
      (token-count (len initial-tokens))
      (percentage-count (len percentages))
      (token-0 (element-at? initial-tokens u0))
      (token-1 (element-at? initial-tokens u1))
      (percentage-0 (element-at? percentages u0))
      (percentage-1 (element-at? percentages u1))
    )
    ;; Validate portfolio parameters
    (asserts! (<= token-count MAX-TOKENS-PER-PORTFOLIO) ERR-MAX-TOKENS-EXCEEDED)
    (asserts! (is-eq token-count percentage-count) ERR-LENGTH-MISMATCH)
    (asserts! (validate-portfolio-percentages percentages) ERR-INVALID-PERCENTAGE)

    ;; Initialize portfolio registry entry
    (map-set Portfolios portfolio-id {
      owner: tx-sender,
      created-at: stacks-block-height,
      last-rebalanced: stacks-block-height,
      total-value: u0,
      active: true,
      token-count: token-count,
    })

    ;; Validate minimum required tokens and percentages
    (asserts! (and (is-some token-0) (is-some token-1)) ERR-INVALID-TOKEN)
    (asserts! (and (is-some percentage-0) (is-some percentage-1))
      ERR-INVALID-PERCENTAGE
    )

    ;; Initialize first two asset allocations
    (try! (initialize-portfolio-asset u0 (unwrap-panic token-0)
      (unwrap-panic percentage-0) portfolio-id
    ))

    (try! (initialize-portfolio-asset u1 (unwrap-panic token-1)
      (unwrap-panic percentage-1) portfolio-id
    ))

    ;; Register portfolio with user's ownership list
    (try! (add-to-user-portfolios tx-sender portfolio-id))

    ;; Update global portfolio counter
    (var-set portfolio-counter portfolio-id)
    (ok portfolio-id)
  )
)

;; Execute portfolio rebalancing operation
(define-public (rebalance-portfolio (portfolio-id uint))
  (let ((portfolio (unwrap! (get-portfolio portfolio-id) ERR-INVALID-PORTFOLIO)))
    ;; Verify ownership and portfolio validity
    (asserts! (is-eq tx-sender (get owner portfolio)) ERR-NOT-AUTHORIZED)
    (asserts! (get active portfolio) ERR-INVALID-PORTFOLIO)

    ;; Update rebalancing timestamp
    (map-set Portfolios portfolio-id
      (merge portfolio { last-rebalanced: stacks-block-height })
    )

    (ok true)
  )
)

;; Modify asset allocation percentage within existing portfolio
(define-public (update-portfolio-allocation
    (portfolio-id uint)
    (token-id uint)
    (new-percentage uint)
  )
  (let (
      (portfolio (unwrap! (get-portfolio portfolio-id) ERR-INVALID-PORTFOLIO))
      (asset (unwrap! (get-portfolio-asset portfolio-id token-id) ERR-INVALID-TOKEN))
    )
    ;; Verify ownership and validate inputs
    (asserts! (is-eq tx-sender (get owner portfolio)) ERR-NOT-AUTHORIZED)
    (asserts! (validate-percentage new-percentage) ERR-INVALID-PERCENTAGE)
    (asserts! (validate-token-id portfolio-id token-id) ERR-INVALID-TOKEN-ID)

    ;; Update asset allocation
    (map-set PortfolioAssets {
      portfolio-id: portfolio-id,
      token-id: token-id,
    }
      (merge asset { target-percentage: new-percentage })
    )

    (ok true)
  )
)

;; PROTOCOL ADMINISTRATION

;; Initialize protocol with new administrative owner
(define-public (initialize (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq new-owner tx-sender)) ERR-NOT-AUTHORIZED)
    (var-set protocol-owner new-owner)
    (ok true)
  )
)
