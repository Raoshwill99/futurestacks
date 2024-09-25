;; FutureStack: Pioneering Real-World Blockchain Solutions with STX
;; Phase 2 Development

;; Define the contract
(define-data-var project-name (string-utf8 50) u"FutureStack")
(define-data-var project-description (string-utf8 200) u"Pioneering Real-World Blockchain Solutions with STX")

;; Define main data structure
(define-map solutions 
  { solution-id: uint }
  { 
    name: (string-utf8 50),
    description: (string-utf8 200),
    impact-area: (string-utf8 50),
    status: (string-utf8 20),
    proposer: principal,
    funds-raised: uint,
    votes: uint
  }
)

;; Initialize solution counter
(define-data-var solution-counter uint u0)

;; Define user roles
(define-map user-roles
  { user: principal }
  { role: (string-utf8 20) }
)

;; Function to add a new solution
(define-public (add-solution (name (string-utf8 50)) (description (string-utf8 200)) (impact-area (string-utf8 50)))
  (let
    (
      (new-id (+ (var-get solution-counter) u1))
    )
    (map-set solutions
      { solution-id: new-id }
      {
        name: name,
        description: description,
        impact-area: impact-area,
        status: u"Proposed",
        proposer: tx-sender,
        funds-raised: u0,
        votes: u0
      }
    )
    (var-set solution-counter new-id)
    (ok new-id)
  )
)

;; Function to get solution details
(define-read-only (get-solution (id uint))
  (map-get? solutions { solution-id: id })
)

;; Function to update solution status
(define-public (update-solution-status (id uint) (new-status (string-utf8 20)))
  (let
    (
      (solution (unwrap! (map-get? solutions { solution-id: id }) (err u404)))
      (user-role (default-to u"member" (get role (map-get? user-roles { user: tx-sender }))))
    )
    (asserts! (is-eq user-role u"admin") (err u403))
    (ok (map-set solutions
      { solution-id: id }
      (merge solution { status: new-status })
    ))
  )
)

;; Function to vote for a solution
(define-public (vote-for-solution (id uint))
  (let
    (
      (solution (unwrap! (map-get? solutions { solution-id: id }) (err u404)))
    )
    (ok (map-set solutions
      { solution-id: id }
      (merge solution { votes: (+ (get votes solution) u1) })
    ))
  )
)

;; Function to donate funds to a solution
(define-public (donate-to-solution (id uint) (amount uint))
  (let
    (
      (solution (unwrap! (map-get? solutions { solution-id: id }) (err u404)))
    )
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (ok (map-set solutions
      { solution-id: id }
      (merge solution { funds-raised: (+ (get funds-raised solution) amount) })
    ))
  )
)

;; Function to set user role
(define-public (set-user-role (user principal) (role (string-utf8 20)))
  (let
    (
      (caller-role (default-to u"member" (get role (map-get? user-roles { user: tx-sender }))))
    )
    (asserts! (is-eq caller-role u"admin") (err u403))
    (ok (map-set user-roles { user: user } { role: role }))
  )
)

;; Function to get user role
(define-read-only (get-user-role (user principal))
  (default-to u"member" (get role (map-get? user-roles { user: user })))
)