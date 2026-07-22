(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local get-table-by-id (. world-api :get-table-by-id))
(local run-updates (. world-api :run-updates))
(local world-mod (require :world))
(local util (require :shared.util))

;; Win checks read marks per cell via get-table-by-id. For iterating
;; entities that share several component types, Lux provides
;; world/call-on-common-components — better suited to movement/collision
;; systems than line-based board rules.

(local winning-lines
  [[1 1 1 2 1 3]
   [2 1 2 2 2 3]
   [3 1 3 2 3 3]
   [1 1 2 1 3 1]
   [1 2 2 2 3 2]
   [1 3 2 3 3 3]
   [1 1 2 2 3 3]
   [1 3 2 2 3 1]])

(fn player-label [player]
  (tostring player))

(fn other-player [player]
  (if (= player :X) :O :X))

(fn pick-first-player []
  (if (= (math.random 2) 1) :X :O))

(fn mark->display [player]
  (if (or (not player) (= player :empty)) "[]" (tostring player)))

(fn get-mark [world entity-id]
  (let [components (get-table-by-id world entity-id)]
    (when components (. components.mark 1))))

(fn cell-empty? [world entity-id]
  (let [mark (get-mark world entity-id)]
    (or (= mark nil) (= mark :empty))))

(fn format-board-line [world cell-at]
  (var parts [])
  (for [row 1 3]
    (for [col 1 3]
      (let [entity-id (. cell-at (world-mod.cell-key row col))
            mark (get-mark world entity-id)]
        (table.insert parts (.. row "," col ": " (mark->display mark))))))
  (.. "(" (table.concat parts ", ") ")"))

(fn apply-move [game player row col]
  (if (or (not row) (not col) (< row 1) (> row 3) (< col 1) (> col 3))
      false
      (let [world game.world
            cell-at game.cell-at
            entity-id (. cell-at (world-mod.cell-key row col))]
        (if (or (not entity-id) (not (cell-empty? world entity-id)))
            false
            (let [mark-updates {}]
              (tset mark-updates entity-id [player])
              (run-updates world {:mark mark-updates})
              true)))))

(fn winner [game]
  (let [world game.world
        cell-at game.cell-at]
    (var result nil)
    (each [_ line (ipairs winning-lines)]
      (let [[r1 c1 r2 c2 r3 c3] line
            id1 (. cell-at (world-mod.cell-key r1 c1))
            id2 (. cell-at (world-mod.cell-key r2 c2))
            id3 (. cell-at (world-mod.cell-key r3 c3))
            m1 (get-mark world id1)
            m2 (get-mark world id2)
            m3 (get-mark world id3)]
        (when (and (or (= m1 :X) (= m1 :O)) (= m1 m2) (= m2 m3))
          (set result m1))))
    result))

(fn draw? [game]
  (let [world game.world
        cell-at game.cell-at]
    (var full true)
    (for [row 1 3]
      (for [col 1 3]
        (when (cell-empty? world (. cell-at (world-mod.cell-key row col)))
          (set full false))))
    (and full (not (winner game)))))

(fn entity-components [world entity-id]
  (get-table-by-id world entity-id))

(fn hit-test-at [game mx my]
  (let [world game.world
        cell-at game.cell-at]
    (var result nil)
    (for [row 1 3]
      (for [col 1 3]
        (let [entity-id (. cell-at (world-mod.cell-key row col))
              components (entity-components world entity-id)]
          (when (and components (not result))
            (let [[x y w h] components.cell-bounds]
              (when (util.point-in-rect? mx my x y w h)
                (set result {:entity-id entity-id :row row :col col})))))))
    result))

(fn status-text [state]
  (case state.phase
    :playing (.. (player-label state.current-player) "'s turn")
    :ended (or state.message "")))

(fn handle-click [game state mx my]
  (let [hit (hit-test-at game mx my)]
    (when hit
      (let [{:row row :col col} hit]
        (when (apply-move game state.current-player row col)
          (if (winner game)
              {:result :win :winner state.current-player}
              (if (draw? game)
                  {:result :draw}
                  {:result :continue :next-player (other-player state.current-player)})))))))

{:format-board-line format-board-line
 :apply-move apply-move
 :winner winner
 :draw? draw?
 :pick-first-player pick-first-player
 :player-label player-label
 :status-text status-text
 :hit-test-at hit-test-at
 :handle-click handle-click}
