;; FutureStack: Pioneering Real-World Blockchain Solutions with STX
;; Initial Commit

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
    status: (string-utf8 20)
  }
)

;; Initialize solution counter
(define-data-var solution-counter uint u0)

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
        status: u"Proposed"
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
    )
    (ok (map-set solutions
      { solution-id: id }
      (merge solution { status: new-status })
    ))
  )
)