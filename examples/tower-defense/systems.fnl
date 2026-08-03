(local lux-world (require :io.github.emgrasmeder.lux.world))
(local get-table-by-id (. lux-world :get-table-by-id))
(local run-updates (. lux-world :run-updates))
(local run-removals (. lux-world :run-removals))
(local world-mod (require :world))
(local pathfinding (require :pathfinding))
(local waves (require :waves))

(fn distance-squared [x1 y1 x2 y2]
  (+ (* (- x1 x2) (- x1 x2)) (* (- y1 y2) (- y1 y2))))

(fn logical-cell-from-position [x y prefer-row prefer-col]
  (var best-row prefer-row)
  (var best-col prefer-col)
  (var best-dist math.huge)
  (for [row 1 world-mod.GRID-H]
    (for [col 1 world-mod.GRID-W]
      (let [[cx cy] (world-mod.cell-center-at row col)
            dist (distance-squared x y cx cy)]
        (when (or (< dist best-dist)
                  (and (= dist best-dist)
                       (= row prefer-row)
                       (= col prefer-col)))
          (set best-dist dist)
          (set best-row row)
          (set best-col col)))))
  {:row best-row :col best-col})

(fn creep-grid-cells [game state]
  (var cells [])
  (each [_ id (ipairs state.creep-ids)]
    (let [components (get-table-by-id game.world id)]
      (when components
        (table.insert cells {:row (. components.grid-pos 1)
                             :col (. components.grid-pos 2)}))))
  cells)

(fn remove-creep! [game state id]
  (let [removals {}]
    (tset removals id true)
    (run-removals game.world removals))
  (tset state.creep-paths id nil)
  (var kept [])
  (each [_ creep-id (ipairs state.creep-ids)]
    (when (not= creep-id id)
      (table.insert kept creep-id)))
  (tset state :creep-ids kept))

(fn repath-creep! [game state id]
  (let [components (get-table-by-id game.world id)
        row (. components.grid-pos 1)
        col (. components.grid-pos 2)
        path (pathfinding.path-to-exit game.terrain game.grid-w game.grid-h
                                       row col (world-mod.left-opening-cells))]
    (tset state.creep-paths id {:path (or path [])
                               :path-idx (if (and path (> (# path) 1)) 2 1)})))

(fn repath-all-creeps! [game state]
  (each [_ id (ipairs state.creep-ids)]
    (repath-creep! game state id)))

(fn spawn-creep! [game state]
  (let [row (or state.wave-spawn-row (world-mod.pick-random-spawn-row))
        col world-mod.RIGHT-COL
        [x y] (world-mod.cell-center-at row col)
        id (world-mod.create-entity game.world [:position x y
                                                 :grid-pos row col
                                                 :creep])]
    (table.insert state.creep-ids id)
    (repath-creep! game state id)))

(fn move-toward [x y tx ty speed dt]
  (let [dx (- tx x)
        dy (- ty y)
        dist (math.sqrt (+ (* dx dx) (* dy dy)))
        step (* speed dt)]
    (if (<= dist step)
        [tx ty true]
        (let [ratio (/ step dist)]
          [(+ x (* dx ratio)) (+ y (* dy ratio)) false]))))

(fn creep-escaped? [row col]
  (world-mod.left-opening? row col))

(fn advance-creep! [game state id dt]
  (let [components (get-table-by-id game.world id)
        creep-data (. state.creep-paths id)]
    (when (and components creep-data)
      (let [row (. components.grid-pos 1)
            col (. components.grid-pos 2)]
        (if (creep-escaped? row col)
            :escaped
            (let [path (. creep-data :path)
                  path-idx (or (. creep-data :path-idx) 2)
                  speed (* world-mod.CREEP-SPEED world-mod.CELL-SIZE)
                  x (. components.position 1)
                  y (. components.position 2)]
              (if (or (not path) (< (# path) 2))
                  nil
                  (let [target (. path path-idx)
                        prefer-row (or (. target :row) row)
                        prefer-col (or (. target :col) col)
                        [tx ty] (world-mod.cell-center-at prefer-row prefer-col)
                        [nx ny arrived] (move-toward x y tx ty speed dt)]
                    (run-updates game.world {:position {id [nx ny]}})
                    (when (and arrived (< path-idx (# path)))
                      (tset creep-data :path-idx (+ path-idx 1)))
                    (let [logical (logical-cell-from-position nx ny prefer-row prefer-col)]
                      (run-updates game.world {:grid-pos {id [(. logical :row) (. logical :col)]}})
                      (when (creep-escaped? (. logical :row) (. logical :col))
                        :escaped))))))))))

(fn try-place-tower! [game state row col]
  (when (or (= state.phase :playing) (= state.phase :between-waves))
    (let [left-openings (world-mod.left-opening-cells)
          right-openings (world-mod.right-opening-cells)
          creep-cells (creep-grid-cells game state)]
      (when (pathfinding.placement-valid? game.terrain game.grid-w game.grid-h
                                          row col left-openings right-openings
                                          creep-cells true)
        (tset game.terrain (world-mod.cell-key row col) :tower)
        (repath-all-creeps! game state)
        true))))

(fn try-remove-tower! [game state row col]
  (when (or (= state.phase :playing) (= state.phase :between-waves))
    (let [left-openings (world-mod.left-opening-cells)
          right-openings (world-mod.right-opening-cells)
          creep-cells (creep-grid-cells game state)]
      (when (pathfinding.placement-valid? game.terrain game.grid-w game.grid-h
                                          row col left-openings right-openings
                                          creep-cells false)
        (tset game.terrain (world-mod.cell-key row col) :empty)
        (repath-all-creeps! game state)
        true))))

(fn handle-click [game state x y button]
  (when (or (= state.phase :playing) (= state.phase :between-waves))
    (let [cell (world-mod.pixel-to-cell x y)]
      (when cell
        (case button
          1 (try-place-tower! game state (. cell :row) (. cell :col))
          2 (try-remove-tower! game state (. cell :row) (. cell :col))
          _ nil)))))

(fn wave-def [index]
  (. waves index))

(fn wave-count []
  (# waves))

(fn start-wave! [game state]
  (let [def (wave-def state.wave-index)]
    (when def
      (tset state :phase :playing)
      (tset state :wave-spawn-row (world-mod.pick-random-spawn-row))
      (tset state :wave-remaining (. def :count))
      (tset state :spawn-timer world-mod.SPAWN-INTERVAL))))

(fn check-wave-complete! [state]
  (when (and (= state.phase :playing)
             (= state.wave-remaining 0)
             (= (# state.creep-ids) 0))
    (if (< state.wave-index (wave-count))
        (tset state :phase :between-waves)
        (tset state :phase :won))))

(fn update-creeps! [game state dt]
  (var escaped [])
  (each [_ id (ipairs state.creep-ids)]
    (when (= :escaped (advance-creep! game state id dt))
      (table.insert escaped id)))
  (each [_ id (ipairs escaped)]
    (remove-creep! game state id)
    (set state.escapes (+ state.escapes 1)))
  (when (>= state.escapes world-mod.MAX-ESCAPES)
    (tset state :phase :ended))
  (when (not= state.phase :ended)
    (check-wave-complete! state)))

(fn update-spawn! [game state dt]
  (when (and (= state.phase :playing) (> state.wave-remaining 0))
    (set state.spawn-timer (+ state.spawn-timer dt))
    (while (and (> state.wave-remaining 0)
                (>= state.spawn-timer world-mod.SPAWN-INTERVAL))
      (set state.spawn-timer (- state.spawn-timer world-mod.SPAWN-INTERVAL))
      (spawn-creep! game state)
      (set state.wave-remaining (- state.wave-remaining 1)))))

(fn advance-to-next-wave! [game state]
  (when (= state.phase :between-waves)
    (tset state :wave-index (+ state.wave-index 1))
    (start-wave! game state)))

(fn handle-key [game state key]
  (when (= key "return")
    (advance-to-next-wave! game state)))

(fn initial-state []
  (let [state {:phase :playing
               :escapes 0
               :spawn-timer 0
               :wave-index 1
               :wave-remaining 0
               :wave-spawn-row nil
               :creep-ids []
               :creep-paths {}}]
    (start-wave! nil state)
    state))

(fn overlay-text [state]
  (case state.phase
    :ended "GAME OVER — press R"
    :won "YOU WIN — press R"
    :between-waves "Press Enter for next wave"
    _ nil))

(fn step [game state dt]
  (when (= state.phase :playing)
    (update-spawn! game state dt)
    (update-creeps! game state dt)))

{:distance-squared distance-squared
 :logical-cell-from-position logical-cell-from-position
 :creep-grid-cells creep-grid-cells
 :repath-creep! repath-creep!
 :repath-all-creeps! repath-all-creeps!
 :spawn-creep! spawn-creep!
 :move-toward move-toward
 :advance-creep! advance-creep!
 :creep-escaped? creep-escaped?
 :try-place-tower! try-place-tower!
 :try-remove-tower! try-remove-tower!
 :handle-click handle-click
 :handle-key handle-key
 :start-wave! start-wave!
 :advance-to-next-wave! advance-to-next-wave!
 :check-wave-complete! check-wave-complete!
 :wave-def wave-def
 :wave-count wave-count
 :update-creeps! update-creeps!
 :update-spawn! update-spawn!
 :initial-state initial-state
 :overlay-text overlay-text
 :step step
 :remove-creep! remove-creep!}
