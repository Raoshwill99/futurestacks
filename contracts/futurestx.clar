;; FutureStack: Pioneering Real-World Blockchain Solutions with STX
;; Development Phase2 - Voting

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
    votes: uint,
    quadratic-score: uint
  }
)

;; Initialize solution counter
(define-data-var solution-counter uint u0)

;; Define user roles
(define-map user-roles
  { user: principal }
  { role: (string-utf8 20) }
)

;; Define user voting credits
(define-map user-voting-credits
  { user: principal }
  { credits: uint }
)

;; Define user votes
(define-map user-votes
  { user: principal, solution-id: uint }
  { votes: uint }
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
        votes: u0,
        quadratic-score: u0
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

;; Function to initialize user voting credits
(define-public (initialize-voting-credits (user principal) (initial-credits uint))
  (let
    (
      (caller-role (default-to u"member" (get role (map-get? user-roles { user: tx-sender }))))
    )
    (asserts! (is-eq caller-role u"admin") (err u403))
    (ok (map-set user-voting-credits { user: user } { credits: initial-credits }))
  )
)

;; Function to get user voting credits
(define-read-only (get-voting-credits (user principal))
  (default-to u0 (get credits (map-get? user-voting-credits { user: user })))
)

;; Function to vote for a solution using quadratic voting
(define-public (quadratic-vote-for-solution (id uint) (vote-count uint))
  (let
    (
      (solution (unwrap! (map-get? solutions { solution-id: id }) (err u404)))
      (user-credits (get-voting-credits tx-sender))
      (cost (* vote-count vote-count))
      (current-votes (default-to u0 (get votes (map-get? user-votes { user: tx-sender, solution-id: id }))))
    )
    (asserts! (<= cost user-credits) (err u401))
    (map-set user-voting-credits
      { user: tx-sender }
      { credits: (- user-credits cost) }
    )
    (map-set user-votes
      { user: tx-sender, solution-id: id }
      { votes: (+ current-votes vote-count) }
    )
    (ok (map-set solutions
      { solution-id: id }
      (merge solution 
        { 
          votes: (+ (get votes solution) vote-count),
          quadratic-score: (+ (get quadratic-score solution) (sqrti cost))
        }
      )
    ))
  )
)

;; Function to donate to a solution
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

;; Helper function to calculate square root of an integer
(define-private (sqrti (y uint))
  (let loop ((x u1))
    (if (> x y)
      (- x u1)
      (loop (+ u1 (/ y x)))
    )
  )
)