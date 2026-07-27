(local lux-world (require :io.github.emgrasmeder.lux.world))
(local get-table-by-id (. lux-world :get-table-by-id))
(local select-entities (. lux-world :select-entities-with-components))
(local c (require :constants))
(local flight (require :flight))

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

(fn step-red-ai [game w plane-id comps _dt]
  (let [[px py] comps.position
        [mode target _fire aux] comps.plane-ai
        heading (. comps.heading 1)]
    (if (= mode :wreck)
        {:mode :wreck :target 0 :aux 0 :desired heading}
        (do
          (var new-mode mode)
          (var new-target target)
          (var new-aux aux)
          (var desired heading)
          (when (or (= mode :hunt) (and (= mode :strafe) (= target 0)))
            (let [bid (pick-strafe-building game w plane-id)]
              (when bid
                (set new-mode :strafe)
                (set new-target bid)
                (set new-aux bid))))
          (if (and (= new-mode :strafe) (> new-aux 0))
              (let [b (get-table-by-id w new-aux)]
                (if (or (not b) (<= (. b.hp 1) 0))
                    (set desired heading)
                    (let [[bx by] b.position
                          d-to-building (flight.dist px py bx by)]
                      (set desired (if (< d-to-building 90)
                                     (flight.desired-heading-to px py bx (+ by 40))
                                     (flight.desired-heading-to px py bx (- by 120)))))))
              (let [nid (nearest-red w px py)]
                (when nid
                  (let [t (get-table-by-id w nid)
                        [tx ty] t.position]
                    (set desired (flight.desired-heading-to px py tx ty))))))
          {:mode new-mode :target new-target :aux new-aux :desired desired}))))

(fn step-green-ai [w plane-id comps _dt]
  (let [[px py] comps.position
        heading (. comps.heading 1)
        intercept (find-intercept-red w)
        target (or intercept (nearest-red w px py))
        desired (if target
                  (let [t (get-table-by-id w target)
                        [tx ty] t.position]
                    (flight.desired-heading-to px py tx ty))
                  heading)]
    {:mode :hunt :target (or target 0) :aux 0 :desired desired}))

(fn step-grey-ai [comps]
  (let [[px _py] comps.position
        [mode _target _fire _aux] comps.plane-ai
        heading (. comps.heading 1)]
    (if (or (< px -80) (> px (+ c.WINDOW-W 80)))
        {:mode :done :target 0 :aux 0 :desired heading}
        {:mode mode :target 0 :aux 0 :desired heading})))

(fn turn-rate-for [team]
  (case team
    :red c.RED-TURN-RATE
    :green c.GREEN-TURN-RATE
    _ 1.8))

{:step-red-ai step-red-ai
 :step-green-ai step-green-ai
 :step-grey-ai step-grey-ai
 :nearest-red nearest-red
 :turn-rate-for turn-rate-for}
