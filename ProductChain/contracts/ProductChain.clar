;; Product Warranty and Authenticity Verification Contract
;; A comprehensive smart contract for managing product authenticity, warranties, and ownership transfers
;; Enables manufacturers to register authentic products with warranties and track ownership changes

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PRODUCT-EXISTS (err u101))
(define-constant ERR-PRODUCT-NOT-FOUND (err u102))
(define-constant ERR-NOT-MANUFACTURER (err u103))
(define-constant ERR-NOT-OWNER (err u104))
(define-constant ERR-WARRANTY-EXPIRED (err u105))
(define-constant ERR-INVALID-TRANSFER (err u106))
(define-constant ERR-MANUFACTURER-EXISTS (err u107))

;; Data maps and vars
;; Tracks registered manufacturers and their authorization status
(define-map manufacturers principal bool)

;; Product information including authenticity and warranty details
(define-map products
    { product-id: (string-ascii 50) }
    {
        manufacturer: principal,
        owner: principal,
        model: (string-ascii 100),
        serial-number: (string-ascii 50),
        warranty-months: uint,
        manufacturing-date: uint,
        registration-date: uint,
        is-authentic: bool,
        warranty-claims: uint
    }
)

;; Warranty claim records for audit trail
(define-map warranty-claims
    { claim-id: uint }
    {
        product-id: (string-ascii 50),
        claimant: principal,
        claim-date: uint,
        claim-type: (string-ascii 100),
        status: (string-ascii 20),
        resolution-date: (optional uint)
    }
)

;; Global claim counter for unique claim IDs
(define-data-var claim-counter uint u0)

;; Product transfer history for complete ownership audit trail
(define-map transfer-history
    { transfer-id: uint }
    {
        product-id: (string-ascii 50),
        from-owner: principal,
        to-owner: principal,
        transfer-date: uint,
        transfer-reason: (string-ascii 100)
    }
)

;; Global transfer counter for unique transfer IDs
(define-data-var transfer-counter uint u0)

;; Manufacturer reputation and statistics tracking
(define-map manufacturer-stats
    principal
    {
        products-registered: uint,
        total-warranty-claims: uint,
        resolved-claims: uint,
        reputation-score: uint
    }
)

;; Private functions
;; Validates if the caller is an authorized manufacturer
(define-private (is-valid-manufacturer (manufacturer principal))
    (default-to false (map-get? manufacturers manufacturer))
)

;; Calculates warranty expiration date based on manufacturing date and warranty period
(define-private (get-warranty-expiration (manufacturing-date uint) (warranty-months uint))
    (+ manufacturing-date (* warranty-months u2629746)) ;; Approximate seconds in a month
)

;; Checks if warranty is still valid for a product
(define-private (is-warranty-valid (product-id (string-ascii 50)))
    (match (map-get? products { product-id: product-id })
        product-data
        (let ((expiration-date (get-warranty-expiration 
                                (get manufacturing-date product-data)
                                (get warranty-months product-data))))
            (< block-height expiration-date))
        false
    )
)

;; Updates manufacturer statistics when products are registered or claims are made
(define-private (update-manufacturer-stats (manufacturer principal) (stat-type (string-ascii 20)))
    (let ((current-stats (default-to 
                            { products-registered: u0, total-warranty-claims: u0, resolved-claims: u0, reputation-score: u100 }
                            (map-get? manufacturer-stats manufacturer))))
        (if (is-eq stat-type "register")
            (map-set manufacturer-stats manufacturer
                (merge current-stats { products-registered: (+ (get products-registered current-stats) u1) }))
            (if (is-eq stat-type "claim")
                (map-set manufacturer-stats manufacturer
                    (merge current-stats { total-warranty-claims: (+ (get total-warranty-claims current-stats) u1) }))
                (if (is-eq stat-type "resolve")
                    (map-set manufacturer-stats manufacturer
                        (merge current-stats { resolved-claims: (+ (get resolved-claims current-stats) u1) }))
                    false)))
    )
)

;; Calculates manufacturer reputation score based on claim resolution rate
(define-private (calculate-reputation-score (total-claims uint) (resolved-claims uint))
    (if (is-eq total-claims u0)
        u100
        (/ (* resolved-claims u100) total-claims)
    )
)

;; Validates product authenticity by checking manufacturer authorization and product registration
(define-private (verify-product-authenticity (product-id (string-ascii 50)))
    (match (map-get? products { product-id: product-id })
        product-data
        (and 
            (get is-authentic product-data)
            (is-valid-manufacturer (get manufacturer product-data))
        )
        false
    )
)

;; Public functions
;; Allows contract owner to register new manufacturers
(define-public (register-manufacturer (manufacturer principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (is-none (map-get? manufacturers manufacturer)) ERR-MANUFACTURER-EXISTS)
        (map-set manufacturers manufacturer true)
        ;; Initialize manufacturer statistics
        (map-set manufacturer-stats manufacturer
            { products-registered: u0, total-warranty-claims: u0, resolved-claims: u0, reputation-score: u100 })
        (ok true)
    )
)

;; Enables manufacturers to register new authentic products with warranty information
(define-public (register-product 
    (product-id (string-ascii 50))
    (model (string-ascii 100))
    (serial-number (string-ascii 50))
    (warranty-months uint)
    (initial-owner principal))
    (begin
        (asserts! (is-valid-manufacturer tx-sender) ERR-NOT-MANUFACTURER)
        (asserts! (is-none (map-get? products { product-id: product-id })) ERR-PRODUCT-EXISTS)
        (map-set products 
            { product-id: product-id }
            {
                manufacturer: tx-sender,
                owner: initial-owner,
                model: model,
                serial-number: serial-number,
                warranty-months: warranty-months,
                manufacturing-date: block-height,
                registration-date: block-height,
                is-authentic: true,
                warranty-claims: u0
            }
        )
        ;; Update manufacturer statistics
        (update-manufacturer-stats tx-sender "register")
        (ok true)
    )
)

;; Enhanced ownership transfer with detailed tracking and validation
(define-public (transfer-ownership 
    (product-id (string-ascii 50)) 
    (new-owner principal)
    (transfer-reason (string-ascii 100)))
    (match (map-get? products { product-id: product-id })
        product-data
        (let ((current-transfer-id (+ (var-get transfer-counter) u1)))
            (begin
                (asserts! (is-eq tx-sender (get owner product-data)) ERR-NOT-OWNER)
                (asserts! (not (is-eq tx-sender new-owner)) ERR-INVALID-TRANSFER)
                (asserts! (verify-product-authenticity product-id) ERR-PRODUCT-NOT-FOUND)
                
                ;; Record transfer in history
                (map-set transfer-history
                    { transfer-id: current-transfer-id }
                    {
                        product-id: product-id,
                        from-owner: tx-sender,
                        to-owner: new-owner,
                        transfer-date: block-height,
                        transfer-reason: transfer-reason
                    }
                )
                
                ;; Update product ownership
                (map-set products 
                    { product-id: product-id }
                    (merge product-data { owner: new-owner })
                )
                
                ;; Increment transfer counter
                (var-set transfer-counter current-transfer-id)
                (ok current-transfer-id)
            )
        )
        ERR-PRODUCT-NOT-FOUND
    )
)

;; Allows manufacturers to resolve warranty claims and update their reputation
(define-public (resolve-warranty-claim 
    (claim-id uint)
    (resolution-notes (string-ascii 200)))
    (match (map-get? warranty-claims { claim-id: claim-id })
        claim-data
        (match (map-get? products { product-id: (get product-id claim-data) })
            product-data
            (begin
                (asserts! (is-eq tx-sender (get manufacturer product-data)) ERR-NOT-MANUFACTURER)
                (asserts! (is-eq (get status claim-data) "pending") ERR-NOT-AUTHORIZED)
                
                ;; Update claim status to resolved
                (map-set warranty-claims
                    { claim-id: claim-id }
                    (merge claim-data 
                        { 
                            status: "resolved",
                            resolution-date: (some block-height)
                        }
                    )
                )
                
                ;; Update manufacturer statistics
                (update-manufacturer-stats tx-sender "resolve")
                (ok true)
            )
            ERR-PRODUCT-NOT-FOUND
        )
        ERR-PRODUCT-NOT-FOUND
    )
)

;; Read-only functions for querying contract data
(define-read-only (get-product-info (product-id (string-ascii 50)))
    (map-get? products { product-id: product-id })
)

(define-read-only (get-manufacturer-stats (manufacturer principal))
    (map-get? manufacturer-stats manufacturer)
)

(define-read-only (get-warranty-claim (claim-id uint))
    (map-get? warranty-claims { claim-id: claim-id })
)

(define-read-only (get-transfer-history (transfer-id uint))
    (map-get? transfer-history { transfer-id: transfer-id })
)

(define-read-only (is-product-authentic (product-id (string-ascii 50)))
    (verify-product-authenticity product-id)
)

(define-read-only (get-warranty-status (product-id (string-ascii 50)))
    (let ((is-valid (is-warranty-valid product-id)))
        (if is-valid
            (some "active")
            (some "expired")
        )
    )
)


