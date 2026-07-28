(local lux-world (require :io.github.emgrasmeder.lux.world))
(local get-table-by-id (. lux-world :get-table-by-id))
(local select-entities (. lux-world :select-entities-with-components))
(local c (require :constants))
(local flight (require :flight))

(fn threat-position [game w flee-id]
  (if (and flee-id (> flee-id 0))
      (let [t (get-table-by-id w flee-id)]
        (when t (. t :position)))
      (let [tid (. game :turret-id)
            t (get-table-by-id w tid)]
        (when t (. t :position)))))

(fn evade-desired-heading [game w px py flee-id]
  (let [pos (threat-position game w flee-id)]
    (if pos
        (let [[tx ty] pos]
          (flight.desired-heading-away px py tx ty))
        nil)))

(fn pick-strafe-building [game w plane-id]
  (let [comps (get-table-by-id w plane-id)]
    (when comps
      (let [[px py] comps.position]
        (var best-id nil)
        (var best-d math.huge)
        (each [_ bid (ipairs (. game :building-ids))]
          (let [b (get-table-by-id w bid)]
            (when (and b (> (. b.hp 1) 0))
              (let [[bx by] b.position
                    d (flight.dist px py bx by)]
                (when (< d best-d)
                  (set best-d d)
                  (set best-id bid))))))
        best-id))))

(fn find-intercept-red [w]
  (var found nil)
  (each [_ id (ipairs (select-entities w [:actor :team :plane-ai :hp]))]
    (let [comps (get-table-by-id w id)]
      (when (and (not found) comps (= (. comps.actor 1) :plane) (= (. comps.team 1) :red)
                 (= (. comps.plane-ai 1) :strafe) (> (. comps.hp 1) 0))
        (set found id))))
  found)

(fn nearest-red [w px py]
  (var best nil)
  (var best-d math.huge)
  (each [_ id (ipairs (select-entities w [:actor :team :position :hp :plane-ai]))]
    (let [comps (get-table-by-id w id)]
      (when (and comps (= (. comps.actor 1) :plane) (= (. comps.team 1) :red) (> (. comps.hp 1) 0)
                 (not= (. comps.plane-ai 1) :wreck))
        (let [[x y] comps.position
              d (flight.dist px py x y)]
          (when (< d best-d)
            (set best-d d)
            (set best id))))))
  best)

(fn green-hunt-target [w px py]
  (or (find-intercept-red w) (nearest-red w px py)))

(fn strafe-building-desired [px py aux-id w]
  (let [b (get-table-by-id w aux-id)]
    (if (or (not b) (<= (. b.hp 1) 0))
        nil
        (let [[bx by] b.position
              d-to-building (flight.dist px py bx by)]
          (if (< d-to-building 90)
              (flight.desired-heading-to px py bx (+ by 40))
              (flight.desired-heading-to px py bx (- by 120)))))))

(fn step-red-ai [game w plane-id comps _dt]
  (let [[px py] comps.position
        [mode target _fire evade-timer] comps.plane-ai
        heading (. comps.heading 1)]
    (if (= mode :wreck)
        {:mode :wreck :target 0 :aux 0 :desired heading}
        (if (and (= mode :evade) (> evade-timer 0))
            (let [desired (or (evade-desired-heading game w px py target) heading)]
              {:mode :evade :target target :aux evade-timer :desired desired})
            (do
              (var new-mode :strafe)
              (var new-target 0)
              (var new-aux 0)
              (var desired heading)
              (let [bid (pick-strafe-building game w plane-id)]
                (when bid
                  (set new-target bid)
                  (set new-aux bid)))
              (let [strafe-h (strafe-building-desired px py new-aux w)]
                (when strafe-h (set desired strafe-h)))
              {:mode new-mode :target new-target :aux new-aux :desired desired})))))

(fn step-green-ai [game w plane-id comps _dt]
  (let [[px py] comps.position
        [mode flee-id _fire evade-timer] comps.plane-ai
        heading (. comps.heading 1)
        hunt (green-hunt-target w px py)]
    (if (and (= mode :evade) (> evade-timer 0))
        (let [desired (or (evade-desired-heading game w px py flee-id) heading)]
          {:mode :evade :target flee-id :aux evade-timer :desired desired})
        (let [desired (if hunt
                        (let [t (get-table-by-id w hunt)
                              [tx ty] t.position]
                          (flight.desired-heading-to px py tx ty))
                        heading)]
          {:mode :hunt :target 0 :aux 0 :desired desired}))))

(fn step-grey-ai [game w comps]
  (let [[px py] comps.position
        [mode flee-id _fire evade-timer aux] comps.plane-ai
        heading (. comps.heading 1)]
    (if (and (= mode :evade) (> evade-timer 0))
        (let [desired (or (evade-desired-heading game w px py flee-id) heading)]
          {:mode :evade :target flee-id :aux evade-timer :desired desired})
        (if (or (< px -80) (> px (+ c.WINDOW-W 80)))
            {:mode :done :target 0 :aux 0 :desired heading}
            {:mode :grey_cross :target 0 :aux aux :desired heading}))))

(fn turn-rate-for [team]
  (case team
    :red c.RED-TURN-RATE
    :green c.GREEN-TURN-RATE
    _ 1.8))

(fn tick-evade-timer [mode aux dt]
  (if (and (= mode :evade) (> aux 0))
      (math.max 0 (- aux dt))
      aux))

{:step-red-ai step-red-ai
 :step-green-ai step-green-ai
 :step-grey-ai step-grey-ai
 :nearest-red nearest-red
 :green-hunt-target green-hunt-target
 :evade-desired-heading evade-desired-heading
 :threat-position threat-position
 :tick-evade-timer tick-evade-timer
 :turn-rate-for turn-rate-for}
