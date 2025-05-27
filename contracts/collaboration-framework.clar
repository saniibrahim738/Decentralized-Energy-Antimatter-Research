;; Decentralized Energy Antimatter Research - Collaboration Framework Contract
;; Facilitates antimatter research cooperation between institutions

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_COLLABORATION_NOT_FOUND (err u401))
(define-constant ERR_ALREADY_PARTNER (err u402))
(define-constant ERR_NOT_PARTNER (err u403))
(define-constant ERR_INVALID_STATUS (err u404))

;; Collaboration status types
(define-constant COLLAB_PROPOSED u0)
(define-constant COLLAB_ACTIVE u1)
(define-constant COLLAB_COMPLETED u2)
(define-constant COLLAB_TERMINATED u3)

;; Data structures
(define-map collaborations
  { collaboration-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    lead-facility: uint,
    status: uint,
    created-at: uint,
    start-date: uint,
    end-date: uint
  }
)

(define-map collaboration-partners
  { collaboration-id: uint, facility-id: uint }
  {
    joined-at: uint,
    contribution-type: (string-ascii 100),
    resource-commitment: uint,
    is-active: bool
  }
)

(define-map resource-sharing
  { collaboration-id: uint, resource-id: uint }
  {
    resource-type: (string-ascii 50),
    provider-facility: uint,
    availability-start: uint,
    availability-end: uint,
    cost-per-unit: uint
  }
)

(define-data-var next-collaboration-id uint u1)
(define-data-var next-resource-id uint u1)

;; Create a new collaboration
(define-public (create-collaboration (title (string-ascii 100)) (description (string-ascii 500)) (lead-facility uint))
  (let ((collaboration-id (var-get next-collaboration-id)))
    (map-set collaborations
      { collaboration-id: collaboration-id }
      {
        title: title,
        description: description,
        lead-facility: lead-facility,
        status: COLLAB_PROPOSED,
        created-at: block-height,
        start-date: u0,
        end-date: u0
      }
    )
    (var-set next-collaboration-id (+ collaboration-id u1))
    (ok collaboration-id)
  )
)

;; Join a collaboration
(define-public (join-collaboration (collaboration-id uint) (facility-id uint) (contribution-type (string-ascii 100)) (resource-commitment uint))
  (begin
    (asserts! (is-some (map-get? collaborations { collaboration-id: collaboration-id })) ERR_COLLABORATION_NOT_FOUND)
    (asserts! (is-none (map-get? collaboration-partners { collaboration-id: collaboration-id, facility-id: facility-id })) ERR_ALREADY_PARTNER)
    (map-set collaboration-partners
      { collaboration-id: collaboration-id, facility-id: facility-id }
      {
        joined-at: block-height,
        contribution-type: contribution-type,
        resource-commitment: resource-commitment,
        is-active: true
      }
    )
    (ok true)
  )
)

;; Add shared resource
(define-public (add-shared-resource (collaboration-id uint) (resource-type (string-ascii 50)) (provider-facility uint) (availability-start uint) (availability-end uint) (cost-per-unit uint))
  (let ((resource-id (var-get next-resource-id)))
    (asserts! (is-some (map-get? collaborations { collaboration-id: collaboration-id })) ERR_COLLABORATION_NOT_FOUND)
    (map-set resource-sharing
      { collaboration-id: collaboration-id, resource-id: resource-id }
      {
        resource-type: resource-type,
        provider-facility: provider-facility,
        availability-start: availability-start,
        availability-end: availability-end,
        cost-per-unit: cost-per-unit
      }
    )
    (var-set next-resource-id (+ resource-id u1))
    (ok resource-id)
  )
)

;; Update collaboration status
(define-public (update-collaboration-status (collaboration-id uint) (new-status uint))
  (begin
    (asserts! (<= new-status COLLAB_TERMINATED) ERR_INVALID_STATUS)
    (match (map-get? collaborations { collaboration-id: collaboration-id })
      collab-data
      (begin
        (map-set collaborations
          { collaboration-id: collaboration-id }
          (merge collab-data { status: new-status })
        )
        (ok true)
      )
      ERR_COLLABORATION_NOT_FOUND
    )
  )
)

;; Read-only functions
(define-read-only (get-collaboration (collaboration-id uint))
  (map-get? collaborations { collaboration-id: collaboration-id })
)

(define-read-only (get-collaboration-partner (collaboration-id uint) (facility-id uint))
  (map-get? collaboration-partners { collaboration-id: collaboration-id, facility-id: facility-id })
)

(define-read-only (get-shared-resource (collaboration-id uint) (resource-id uint))
  (map-get? resource-sharing { collaboration-id: collaboration-id, resource-id: resource-id })
)

(define-read-only (is-active-partner (collaboration-id uint) (facility-id uint))
  (match (map-get? collaboration-partners { collaboration-id: collaboration-id, facility-id: facility-id })
    partner-data (get is-active partner-data)
    false
  )
)
