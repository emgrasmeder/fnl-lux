(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local get-table-by-id (. world-api :get-table-by-id))
(local run-updates (. world-api :run-updates))
(local pathfinding (require :pathfinding))
(local world-mod (require :world))

(fn get-actor-position [game entity-id]
  (let [components (get-table-by-id game.world entity-id)]
    (when components
      {:row (. components.position 1)
       :col (. components.position 2)})))

(fn positions-equal? [a b]
  (and a b (= (. a :row) (. b :row)) (= (. a :col) (. b :col))))

(fn compute-path [game]
  (let [terrain (world-mod.terrain-from-game game)
        start (get-actor-position game game.monster-id)
        goal (get-actor-position game game.goal-id)]
    (pathfinding.find-path terrain start goal game.grid-w game.grid-h)))

(fn set-actor-position! [game entity-id row col]
  (run-updates game.world {:position {entity-id [row col]}}))

(fn pick-reachable-goal [game monster-pos]
  (let [terrain (world-mod.terrain-from-game game)
        empties (world-mod.empty-cells terrain game.grid-w game.grid-h)
        copy []]
    (each [_ cell (ipairs empties)] (table.insert copy cell))
    (world-mod.shuffle! copy)
    (var result nil)
    (each [_ cell (ipairs copy)]
      (when (not result)
        (when (not (positions-equal? cell monster-pos))
          (let [path (pathfinding.find-path terrain monster-pos cell game.grid-w game.grid-h)]
            (when (and path (> (# path) 0))
              (set result cell))))))
    (or result monster-pos)))

(fn relocate-goal! [game]
  (let [monster-pos (get-actor-position game game.monster-id)
        new-goal (pick-reachable-goal game monster-pos)]
    (set-actor-position! game game.goal-id (. new-goal :row) (. new-goal :col))
    new-goal))

(fn replan-path! [state game]
  (tset state :path (or (compute-path game) [])))

(fn actor-label [kind]
  (if (= kind :monster) "X" "O"))

(fn format-grid-line [game]
  (let [world game.world
        cell-at game.cell-at
        monster-pos (get-actor-position game game.monster-id)
        goal-pos (get-actor-position game game.goal-id)]
    (var parts [])
    (for [row 1 game.grid-h]
      (for [col 1 game.grid-w]
        (let [entity-id (. cell-at (world-mod.cell-key row col))
              components (get-table-by-id world entity-id)
              terrain (. components.terrain 1)
              cell-text (if (positions-equal? monster-pos {:row row :col col})
                          "X"
                          (if (positions-equal? goal-pos {:row row :col col})
                              "O"
                              (if (= terrain :wall) "#" ".")))]
          (table.insert parts (.. row "," col ": " cell-text)))))
    (.. "(" (table.concat parts ", ") ")")))

(fn initial-state [game]
  {:path (or (compute-path game) [])
   :step-timer 0})

(fn advance-step! [game state on-catch]
  (let [monster-pos (get-actor-position game game.monster-id)
        goal-pos (get-actor-position game game.goal-id)]
    (if (positions-equal? monster-pos goal-pos)
        (do
          (when on-catch (on-catch))
          (relocate-goal! game)
          (replan-path! state game)
          :caught)
        (if (> (# state.path) 0)
            (let [next-step (. state.path 1)]
              (var remaining [])
              (for [i 2 (# state.path)]
                (table.insert remaining (. state.path i)))
              (set-actor-position! game game.monster-id (. next-step :row) (. next-step :col))
              (tset state :path remaining)
              :moved)
            :idle))))

(fn step-once [game state on-catch]
  (advance-step! game state on-catch))

(fn step [game state dt on-catch]
  (set state.step-timer (+ state.step-timer dt))
  (when (>= state.step-timer 1.0)
    (set state.step-timer (- state.step-timer 1.0))
    (advance-step! game state on-catch)))

{:get-actor-position get-actor-position
 :compute-path compute-path
 :relocate-goal! relocate-goal!
 :replan-path! replan-path!
 :initial-state initial-state
 :step step
 :step-once step-once
 :format-grid-line format-grid-line
 :actor-label actor-label
 :positions-equal? positions-equal?}
