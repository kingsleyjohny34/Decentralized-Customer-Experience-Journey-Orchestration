;; Journey Mapping Contract
;; Maps and manages customer experience journeys

(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_INVALID_JOURNEY (err u301))
(define-constant ERR_INVALID_STAGE (err u302))

;; Data structures
(define-map customer-journeys uint {
  customer-id: (string-ascii 50),
  journey-name: (string-ascii 50),
  current-stage: uint,
  total-stages: uint,
  manager: principal,
  started-at: uint,
  status: (string-ascii 20)
})

(define-map journey-stages uint {
  journey-id: uint,
  stage-number: uint,
  stage-name: (string-ascii 50),
  touchpoint-ids: (list 10 uint),
  completion-criteria: (string-ascii 100),
  completed: bool
})

(define-data-var next-journey-id uint u1)
(define-data-var next-stage-id uint u1)

;; Public functions
(define-public (create-journey
  (customer-id (string-ascii 50))
  (journey-name (string-ascii 50))
  (total-stages uint))
  (let ((journey-id (var-get next-journey-id)))
    (map-set customer-journeys journey-id {
      customer-id: customer-id,
      journey-name: journey-name,
      current-stage: u1,
      total-stages: total-stages,
      manager: tx-sender,
      started-at: block-height,
      status: "active"
    })
    (var-set next-journey-id (+ journey-id u1))
    (ok journey-id)))

(define-public (add-journey-stage
  (journey-id uint)
  (stage-number uint)
  (stage-name (string-ascii 50))
  (touchpoint-ids (list 10 uint))
  (completion-criteria (string-ascii 100)))
  (let ((stage-id (var-get next-stage-id))
        (journey (unwrap! (map-get? customer-journeys journey-id) ERR_INVALID_JOURNEY)))
    (asserts! (is-eq tx-sender (get manager journey)) ERR_UNAUTHORIZED)
    (map-set journey-stages stage-id {
      journey-id: journey-id,
      stage-number: stage-number,
      stage-name: stage-name,
      touchpoint-ids: touchpoint-ids,
      completion-criteria: completion-criteria,
      completed: false
    })
    (var-set next-stage-id (+ stage-id u1))
    (ok stage-id)))

(define-public (complete-stage (journey-id uint) (stage-number uint))
  (let ((journey (unwrap! (map-get? customer-journeys journey-id) ERR_INVALID_JOURNEY)))
    (asserts! (is-eq tx-sender (get manager journey)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get current-stage journey) stage-number) ERR_INVALID_STAGE)
    (map-set customer-journeys journey-id
      (merge journey {current-stage: (+ stage-number u1)}))
    (ok true)))

;; Read-only functions
(define-read-only (get-journey (journey-id uint))
  (map-get? customer-journeys journey-id))

(define-read-only (get-journey-stage (stage-id uint))
  (map-get? journey-stages stage-id))

(define-read-only (get-journey-progress (journey-id uint))
  (match (map-get? customer-journeys journey-id)
    journey (/ (* (get current-stage journey) u100) (get total-stages journey))
    u0))
