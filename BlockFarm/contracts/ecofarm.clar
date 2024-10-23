;; Constants and Error Codes
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-ID-EXISTS (err u2))
(define-constant ERR-ID-NOT-FOUND (err u404))
(define-constant ERR-INVALID-VALUE (err u3))
(define-constant ERR-NOT-INITIALIZED (err u4))
(define-constant ERR-INVALID-ID (err u5))

;; Global Variables
(define-data-var contract-initialized bool false)

;; Data Maps
(define-map resources
    {id: uint}
    {
        name: (string-ascii 50),
        quantity: uint,
        unit-price: uint,
        validated: bool
    }
)

(define-map labor
    {id: uint}
    {
        name: (string-ascii 50),
        hourly-rate: uint,
        validated: bool
    }
)

(define-map equipment
    {id: uint}
    {
        name: (string-ascii 50),
        maintenance-schedule: (string-ascii 50),
        validated: bool
    }
)

;; Private Helper Functions
(define-private (validate-and-sanitize-id (value uint))
    (if (and (> value u0) (< value u1000000))
        (ok value)
        (err ERR-INVALID-ID))
)

(define-private (validate-and-sanitize-string (value (string-ascii 50)))
    (if (and (not (is-eq value "")) (>= (len value) u1) (<= (len value) u50))
        (ok value)
        (err ERR-INVALID-VALUE))
)

(define-private (validate-and-sanitize-uint (value uint))
    (if (and (> value u0) (< value u1000000000))
        (ok value)
        (err ERR-INVALID-VALUE))
)

(define-private (check-owner)
    (if (is-eq tx-sender CONTRACT-OWNER)
        (ok true)
        (err ERR-NOT-AUTHORIZED))
)

(define-private (check-initialized)
    (if (var-get contract-initialized)
        (ok true)
        (err ERR-NOT-INITIALIZED))
)

;; Public Functions
(define-public (initialize-contract)
    (begin
        (try! (check-owner))
        (if (not (var-get contract-initialized))
            (begin
                (var-set contract-initialized true)
                (ok "Contract initialized successfully"))
            (err ERR-NOT-AUTHORIZED))
    )
)

(define-public (add-resource (id uint) (name (string-ascii 50)) (quantity uint) (unit-price uint))
    (match (check-owner)
        owner-ok (match (check-initialized)
                        init-ok (match (validate-and-sanitize-id id)
                                       validated-id (match (validate-and-sanitize-string name)
                                                           validated-name (match (validate-and-sanitize-uint quantity)
                                                                                 validated-quantity (match (validate-and-sanitize-uint unit-price)
                                                                                                           validated-unit-price 
                                                                                                           ;; Proceed only if all validations pass
                                                                                                           (if (is-none (map-get? resources {id: validated-id}))
                                                                                                               (ok (map-insert resources
                                                                                                                               {id: validated-id}
                                                                                                                               {
                                                                                                                                   name: validated-name,
                                                                                                                                   quantity: validated-quantity,
                                                                                                                                   unit-price: validated-unit-price,
                                                                                                                                   validated: true
                                                                                                                               }))
                                                                                                               (err ERR-ID-EXISTS))
                                                                                                           unit-price-err (err unit-price-err))
                                                                                 quantity-err (err quantity-err))
                                                           name-err (err name-err))
                                       id-err (err id-err))
                        init-err (err init-err))
        owner-err (err owner-err)))
