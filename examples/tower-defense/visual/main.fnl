(local world-mod (require :world))
(local systems (require :systems))
(local ui (require :ui))
(local creep-draw (require :creep-draw))
(local bullet-draw (require :bullet-draw))
(local visual (require :shared.testing.visual-runner))

(local WIN-W 680)
(local WIN-H 688)
(local ISO-W 80)
(local ISO-H 80)

(fn build-full [build-fn]
  (math.randomseed 42)
  (let [game (world-mod.create-game-world)
        state (systems.initial-state)]
    (build-fn game state)
    (values game state)))

(local scenarios
  [{:name "creep-bob-0" :kind :creep-bob :phase 0}
   {:name "creep-bob-1" :kind :creep-bob :phase 1.5707963267948966}
   {:name "bullet-mid" :kind :bullet}
   {:name "initial" :kind :full
    :build (fn [game state])}
   {:name "with-tower" :kind :full
    :build (fn [game state]
             (systems.try-place-tower! game state 15 15))}
   {:name "with-creeps" :kind :full
    :build (fn [game state]
             (systems.play! game state)
             (systems.spawn-creep! game state)
             (systems.update-creeps! game state 0.5))}
   {:name "with-bullet" :kind :full
    :build (fn [game state]
             (systems.play! game state)
             (systems.try-place-tower! game state 15 15)
             (let [[near-x near-y] (world-mod.cell-center-at 15 18)
                   id (world-mod.create-entity game.world
                                               [:position near-x near-y
                                                :grid-pos 15 18
                                                :hp world-mod.CREEP-HP
                                                :creep])]
               (table.insert state.creep-ids id)
               (tset state.creep-paths id {:path [] :path-idx 1 :walk-phase 0.5})
               (let [tower (. state.towers (world-mod.cell-key 15 15))]
                 (tset tower :cooldown 0)
                 (systems.update-towers! game state 0)
                 (systems.update-bullets! game state 0.04))))}
   {:name "game-over" :kind :full
    :build (fn [game state]
             (tset state :phase :ended)
             (tset state :escapes 10))}
   {:name "building" :kind :full
    :build (fn [game state]
             (tset state :wave-index 2)
             (tset state :phase :building))}
   {:name "stats-open" :kind :full
    :build (fn [game state]
             (systems.try-place-tower! game state 15 15)
             (tset state :stats-open true)
             (tset state :kills 0)
             (tset state :escapes 3))}])

(fn render-scenario! [scenario]
  (case scenario.kind
    :creep-bob
    (let [canvas (visual.capture-window ISO-W ISO-H)]
      (creep-draw.render-creep! (/ ISO-W 2) (/ ISO-H 2)
                                world-mod.CREEP-DRAW-RADIUS scenario.phase)
      (visual.finish-capture canvas))
    :bullet
    (let [canvas (visual.capture-window ISO-W ISO-H)]
      (bullet-draw.render-bullet! (/ ISO-W 2) (/ ISO-H 2) world-mod.BULLET-RADIUS)
      (visual.finish-capture canvas))
    :full
    (let [(game state) (build-full scenario.build)
          canvas (visual.capture-window WIN-W WIN-H)]
      (ui.render game state)
      (visual.finish-capture canvas))))

(local loop (visual.make-loop scenarios render-scenario!))

(fn love.load [args] ((. loop :love.load) args))
(fn love.draw [] ((. loop :love.draw)))
