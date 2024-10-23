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

;; Input Validation Functions
(define-private (is-valid-id (value uint))
    (and (> value u0) (< value u1000000))
)

(define-private (is-valid-string (value (string-ascii 50)))
    (and (not (is-eq value "")) (>= (len value) u1) (<= (len value) u50))
)

(define-private (is-valid-uint (value uint))
    (and (> value u0) (< value u1000000000))
)

;; Authorization Functions
(define-private (assert-contract-owner)
    (if (is-eq tx-sender CONTRACT-OWNER)
        (ok true)
        ERR-NOT-AUTHORIZED
    )
)

(define-private (assert-initialized)
    (if (var-get contract-initialized)
        (ok true)
        ERR-NOT-INITIALIZED
    )
)

;; Helper Functions
(define-private (validate-equipment-name (name (string-ascii 50)))
    (if (is-valid-string name)
        (ok name)
        ERR-INVALID-VALUE)
)

(define-private (validate-maintenance-schedule (schedule (string-ascii 50)))
    (if (is-valid-string schedule)
        (ok schedule)
        ERR-INVALID-VALUE)
)

;; Public Functions
(define-public (initialize-contract)
    (begin
        (try! (assert-contract-owner))
        (asserts! (not (var-get contract-initialized)) ERR-NOT-AUTHORIZED)
        (var-set contract-initialized true)
        (ok true))
)

(define-public (add-resource (id uint) (name (string-ascii 50)) (quantity uint) (unit-price uint))
    (begin
        ;; Initial input validation
        (asserts! (is-valid-id id) ERR-INVALID-ID)
        (asserts! (is-valid-string name) ERR-INVALID-VALUE)
        (asserts! (is-valid-uint quantity) ERR-INVALID-VALUE)
        (asserts! (is-valid-uint unit-price) ERR-INVALID-VALUE)
        
        ;; Authorization checks
        (try! (assert-initialized))
        (try! (assert-contract-owner))
        
        ;; Business logic
        (asserts! (is-none (map-get? resources {id: id})) ERR-ID-EXISTS)
        (ok (map-insert resources
            {id: id}
            {
                name: name,
                quantity: quantity,
                unit-price: unit-price,
                validated: true
            }))
    )
)

(define-public (add-labor (id uint) (name (string-ascii 50)) (hourly-rate uint))
    (begin
        ;; Initial input validation
        (asserts! (is-valid-id id) ERR-INVALID-ID)
        (asserts! (is-valid-string name) ERR-INVALID-VALUE)
        (asserts! (is-valid-uint hourly-rate) ERR-INVALID-VALUE)
        
        ;; Authorization checks
        (try! (assert-initialized))
        (try! (assert-contract-owner))
        
        ;; Business logic
        (asserts! (is-none (map-get? labor {id: id})) ERR-ID-EXISTS)
        (ok (map-insert labor
            {id: id}
            {
                name: name,
                hourly-rate: hourly-rate,
                validated: true
            }))
    )
)

(define-public (add-equipment (id uint) (name (string-ascii 50)) (maintenance-schedule (string-ascii 50)))
    (begin
        ;; Initial input validation
        (asserts! (is-valid-id id) ERR-INVALID-ID)
        (asserts! (is-valid-string name) ERR-INVALID-VALUE)
        (asserts! (is-valid-string maintenance-schedule) ERR-INVALID-VALUE)
        
        ;; Authorization checks
        (try! (assert-initialized))
        (try! (assert-contract-owner))
        
        ;; Business logic
        (asserts! (is-none (map-get? equipment {id: id})) ERR-ID-EXISTS)
        (ok (map-insert equipment
            {id: id}
            {
                name: name,
                maintenance-schedule: maintenance-schedule,
                validated: true
            }))
    )
)

;; Add stricter validation functions
(define-private (validate-equipment-string (value (string-ascii 50)))
    (if (and 
            (is-valid-string value)
            ;; Add additional validation rules as needed
            (not (is-eq value ""))
            (<= (len value) u50)
            ;; Could add more specific rules here
        )
        (ok value)
        ERR-INVALID-VALUE)
)

(define-private (validate-optional-equipment-string (opt-value (optional (string-ascii 50))) (current-value (string-ascii 50)))
    (match opt-value
        value (validate-equipment-string value)
        (ok current-value)
    )
)

(define-public (update-equipment (id uint) (new-name (optional (string-ascii 50))) (new-maintenance-schedule (optional (string-ascii 50))))
    (begin
        ;; Initial input validation
        (asserts! (is-valid-id id) ERR-INVALID-ID)
        
        ;; Authorization checks
        (try! (assert-initialized))
        (try! (assert-contract-owner))
        
        ;; Business logic
        (match (map-get? equipment {id: id})
            equipment-data
            (let
                (
                    ;; Get current values
                    (current-name (get name equipment-data))
                    (current-schedule (get maintenance-schedule equipment-data))
                    
                    ;; Validate new values with explicit error handling
                    (validated-name (try! (validate-optional-equipment-string new-name current-name)))
                    (validated-schedule (try! (validate-optional-equipment-string new-maintenance-schedule current-schedule)))
                )
                
                ;; Additional post-validation checks
                (asserts! (is-valid-string validated-name) ERR-INVALID-VALUE)
                (asserts! (is-valid-string validated-schedule) ERR-INVALID-VALUE)
                
                ;; Update with fully validated data
                (ok (map-set equipment
                    {id: id}
                    {
                        name: validated-name,
                        maintenance-schedule: validated-schedule,
                        validated: true
                    }))
            )
            ERR-ID-NOT-FOUND
        )
    )
)

(define-public (delete-equipment (id uint))
    (begin
        ;; Initial input validation
        (asserts! (is-valid-id id) ERR-INVALID-ID)
        
        ;; Authorization checks
        (try! (assert-initialized))
        (try! (assert-contract-owner))
        
        ;; Business logic
        (asserts! (is-some (map-get? equipment {id: id})) ERR-ID-NOT-FOUND)
        (ok (map-delete equipment {id: id}))
    )
)

(define-public (view-equipment (id uint))
    (begin
        ;; Initial input validation
        (asserts! (is-valid-id id) ERR-INVALID-ID)
        
        ;; Authorization check
        (try! (assert-initialized))
        
        ;; Business logic
        (match (map-get? equipment {id: id})
            equipment-data (ok equipment-data)
            ERR-ID-NOT-FOUND)
    )
)