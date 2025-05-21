;; Title: CreditStack - Decentralized Credit Scoring and Lending Protocol
;;
;; Summary: A Bitcoin-native lending protocol with on-chain credit scoring
;;
;; Description: CreditStack enables permissionless lending on Stacks with an integrated 
;; reputation system. Users build credit scores by successfully repaying loans, unlocking
;; better rates and lower collateral requirements over time. The protocol includes 
;; governance mechanisms for risk parameters and provides composable credit history
;; for the broader Bitcoin DeFi ecosystem.

;; CONTRACT ADMINISTRATION

(define-constant CONTRACT-OWNER tx-sender)

;; ERROR CODES

(define-constant ERR-UNAUTHORIZED (err u1))
(define-constant ERR-INSUFFICIENT-BALANCE (err u2))
(define-constant ERR-INVALID-AMOUNT (err u3))
(define-constant ERR-LOAN-NOT-FOUND (err u4))
(define-constant ERR-LOAN-DEFAULTED (err u5))
(define-constant ERR-INSUFFICIENT-SCORE (err u6))
(define-constant ERR-ACTIVE-LOAN (err u7))
(define-constant ERR-NOT-DUE (err u8))
(define-constant ERR-INVALID-DURATION (err u9))
(define-constant ERR-INVALID-LOAN-ID (err u10))

;; CREDIT SCORE PARAMETERS

(define-constant MIN-SCORE u50) ;; Minimum possible credit score
(define-constant MAX-SCORE u100) ;; Maximum possible credit score
(define-constant MIN-LOAN-SCORE u70) ;; Minimum score required for loan eligibility

;; DATA MAPS

;; Stores user credit profiles and history
(define-map UserScores
  { user: principal }
  {
    score: uint, ;; Current credit score (50-100)
    total-borrowed: uint, ;; Lifetime amount borrowed
    total-repaid: uint, ;; Lifetime amount repaid
    loans-taken: uint, ;; Count of total loans taken
    loans-repaid: uint, ;; Count of loans successfully repaid
    last-update: uint, ;; Block height of last update
  }
)

;; Stores individual loan data with full repayment tracking
(define-map Loans
  { loan-id: uint }
  {
    borrower: principal, ;; Loan recipient
    amount: uint, ;; Principal amount in STX
    collateral: uint, ;; Collateral amount in STX
    due-height: uint, ;; Block height when loan is due
    interest-rate: uint, ;; Interest rate in percentage
    is-active: bool, ;; Whether loan is currently active
    is-defaulted: bool, ;; Whether loan has defaulted
    repaid-amount: uint, ;; Amount repaid so far
  }
)

;; Maps users to their active loans for quick lookups
(define-map UserLoans
  { user: principal }
  { active-loans: (list 20 uint) } ;; List of active loan IDs, max 20
)

;; STATE VARIABLES

;; Auto-incrementing loan ID counter
(define-data-var next-loan-id uint u0)

;; Tracks total STX locked as collateral
(define-data-var total-stx-locked uint u0)

;; PUBLIC FUNCTIONS

;; Initialize a new user's credit score
;; This must be called before a user can request any loans
(define-public (initialize-score)
  (let ((sender tx-sender))
    (asserts! (is-none (map-get? UserScores { user: sender })) ERR-UNAUTHORIZED)
    (ok (map-set UserScores { user: sender } {
      score: MIN-SCORE,
      total-borrowed: u0,
      total-repaid: u0,
      loans-taken: u0,
      loans-repaid: u0,
      last-update: stacks-block-height,
    }))
  )
)