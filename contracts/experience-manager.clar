;; Experience Manager Verification Contract
;; Manages and verifies customer experience managers

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_EXISTS (err u101))
(define-constant ERR_NOT_FOUND (err u102))

;; Data structures
(define-map experience-managers principal {
  name: (string-ascii 50),
  verified: bool,
  certification-level: uint,
  registered-at: uint
})

(define-map manager-stats principal {
  total-journeys: uint,
  satisfaction-score: uint,
  active-touchpoints: uint
})

;; Public functions
(define-public (register-manager (name (string-ascii 50)) (certification-level uint))
  (let ((manager tx-sender))
    (asserts! (is-none (map-get? experience-managers manager)) ERR_ALREADY_EXISTS)
    (map-set experience-managers manager {
      name: name,
      verified: false,
      certification-level: certification-level,
      registered-at: block-height
    })
    (map-set manager-stats manager {
      total-journeys: u0,
      satisfaction-score: u0,
      active-touchpoints: u0
    })
    (ok true)))

(define-public (verify-manager (manager principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? experience-managers manager)) ERR_NOT_FOUND)
    (map-set experience-managers manager
      (merge (unwrap-panic (map-get? experience-managers manager))
             {verified: true}))
    (ok true)))

;; Read-only functions
(define-read-only (get-manager-info (manager principal))
  (map-get? experience-managers manager))

(define-read-only (is-verified-manager (manager principal))
  (match (map-get? experience-managers manager)
    manager-data (get verified manager-data)
    false))

(define-read-only (get-manager-stats (manager principal))
  (map-get? manager-stats manager))
