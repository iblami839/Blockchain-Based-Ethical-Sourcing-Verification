;; Supplier Certification Contract
;; This contract validates compliance with ethical standards

(define-data-var admin principal tx-sender)

;; Data structures
(define-map suppliers
  { supplier-id: (string-ascii 64) }
  {
    principal: principal,
    name: (string-ascii 100),
    location: (string-ascii 100),
    certification-status: (string-ascii 20),
    certification-date: uint,
    certification-expiry: uint,
    standards-compliance: (list 10 (string-ascii 50))
  }
)

;; Events
(define-public (register-supplier (supplier-id (string-ascii 64)) (name (string-ascii 100)) (location (string-ascii 100)) (standards-compliance (list 10 (string-ascii 50))))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-set suppliers
      { supplier-id: supplier-id }
      {
        principal: tx-sender,
        name: name,
        location: location,
        certification-status: "pending",
        certification-date: u0,
        certification-expiry: u0,
        standards-compliance: standards-compliance
      }
    )
    (ok true)
  )
)

(define-public (certify-supplier (supplier-id (string-ascii 64)) (status (string-ascii 20)) (expiry uint))
  (let
    ((current-time (unwrap-panic (get-block-info? time u0)))
     (supplier-info (map-get? suppliers { supplier-id: supplier-id })))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some supplier-info) (err u404))
    (map-set suppliers
      { supplier-id: supplier-id }
      (merge (unwrap-panic supplier-info)
        {
          certification-status: status,
          certification-date: current-time,
          certification-expiry: expiry
        }
      )
    )
    (ok true)
  )
)

(define-read-only (get-supplier-info (supplier-id (string-ascii 64)))
  (map-get? suppliers { supplier-id: supplier-id })
)

(define-read-only (is-supplier-certified (supplier-id (string-ascii 64)))
  (let
    ((supplier-info (map-get? suppliers { supplier-id: supplier-id }))
     (current-time (unwrap-panic (get-block-info? time u0))))
    (if (is-some supplier-info)
      (let
        ((info (unwrap-panic supplier-info)))
        (and
          (is-eq (get certification-status info) "certified")
          (> (get certification-expiry info) current-time)
        )
      )
      false
    )
  )
)

(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)

