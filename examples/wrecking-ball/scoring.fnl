(local physics-world (require :physics-world))

(fn dist [sx sy x y]
  (math.sqrt (+ (* (- x sx) (- x sx)) (* (- y sy) (- y sy)))))

(fn initial-round-state []
  {:bricks {}
   :target-building-id nil
   :neighbor-ids {}
   :target-cleared? false})

(fn begin-round! [score target-building-id neighbor-ids]
  (tset score :target-building-id target-building-id)
  (tset score :neighbor-ids neighbor-ids)
  (tset score :bricks {})
  (tset score :target-cleared? false))

(fn register-spawn! [score spawn lux-id]
  (tset (. score :bricks) lux-id
        {:lux-id lux-id
         :building-id (. spawn :building-id)
         :target? (. spawn :target?)
         :sx (. spawn :x)
         :sy (. spawn :y)
         :last-x (. spawn :x)
         :last-y (. spawn :y)
         :removed? false}))

(fn sync-live-positions! [score pw]
  (each [_ rec (ipairs (. pw :brick-records))]
    (let [id (. rec :lux-id)
          entry (. (. score :bricks) id)]
      (when entry
        (let [[x y] (physics-world.body-xy (. rec :body))]
          (tset entry :last-x x)
          (tset entry :last-y y))))))

(fn neighbor-penalty? [score building-id target?]
  (and (not target?)
       building-id
       (. score :neighbor-ids)
       (. (. score :neighbor-ids) building-id)))

(fn on-bricks-removed! [score removed-by-id]
  (var delta 0)
  (each [_ info (pairs removed-by-id)]
    (let [id (. info :lux-id)
          entry (. (. score :bricks) id)]
      (when entry
        (tset entry :removed? true)
        (tset entry :last-x (. info :rx))
        (tset entry :last-y (. info :ry))
        (when (neighbor-penalty? score (. entry :building-id) (. entry :target?))
          (set delta (- delta (dist (. entry :sx) (. entry :sy)
                                   (. info :rx) (. info :ry))))))))
  (tset score :total-score (+ (. score :total-score) delta))
  delta)

(fn brick-final-pos [entry]
  [(. entry :last-x) (. entry :last-y)])

(fn target-fully-destroyed? [score pw]
  (and (. score :target-building-id)
       (= (physics-world.target-bricks-remaining pw) 0)))

(fn compute-target-bonus [score]
  (var bonus 0)
  (each [_ entry (pairs (. score :bricks))]
    (when (. entry :target?)
      (let [[fx fy] (brick-final-pos entry)]
        (set bonus (+ bonus (dist (. entry :sx) (. entry :sy) fx fy))))))
  bonus)

(fn end-round! [score pw]
  (sync-live-positions! score pw)
  (let [cleared (target-fully-destroyed? score pw)
        bonus (if cleared (compute-target-bonus score) 0)
        new-total (+ (. score :total-score) bonus)]
    (tset score :total-score new-total)
    (tset score :target-cleared? cleared)
    (table.insert (. score :round-scores) bonus)
    {:round-bonus bonus :target-cleared cleared :total-score new-total}))

(fn initial-game-score []
  {:total-score 0
   :round-scores []
   :target-building-id nil
   :neighbor-ids {}
   :bricks {}
   :target-cleared? false})

(fn reset-game-score! [score]
  (tset score :total-score 0)
  (tset score :round-scores [])
  (begin-round! score nil {}))

{:dist dist
 :initial-game-score initial-game-score
 :reset-game-score! reset-game-score!
 :begin-round! begin-round!
 :register-spawn! register-spawn!
 :sync-live-positions! sync-live-positions!
 :on-bricks-removed! on-bricks-removed!
 :end-round! end-round!
 :target-fully-destroyed? target-fully-destroyed?
 :neighbor-penalty? neighbor-penalty?}
