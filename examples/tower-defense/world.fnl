(local world (require :io.github.emgrasmeder.lux.world))
(local create (. world :create))
(local create-entity (. world :create-entity))
(local grid (require :shared.grid))

(local GRID-W 30)
(local GRID-H 30)
(local CELL-SIZE 20)
(local BOARD-OX 40)
(local BOARD-OY 40)
(local OPENING-SIZE 12)
(local OPENING-START-ROW 10)
(local OPENING-END-ROW 21)
(local LEFT-COL 1)
(local RIGHT-COL 30)
(local MAX-ESCAPES 10)
(local CREEP-SPEED 3)
(local SPAWN-INTERVAL 1.0)

(fn cell-key [row col] (grid.pos-key row col))

(fn cell-bounds-at [row col]
  (grid.cell-bounds-at BOARD-OX BOARD-OY CELL-SIZE row col))

(fn cell-center-at [row col]
  (let [[x y w h] (cell-bounds-at row col)]
    [(+ x (/ w 2)) (+ y (/ h 2))]))

(fn window-width [] (grid.window-width BOARD-OX GRID-W CELL-SIZE))
(fn window-height [] (grid.window-height BOARD-OY GRID-H CELL-SIZE))

(fn left-opening? [row col]
  (and (= col LEFT-COL)
       (>= row OPENING-START-ROW)
       (<= row OPENING-END-ROW)))

(fn right-opening? [row col]
  (and (= col RIGHT-COL)
       (>= row OPENING-START-ROW)
       (<= row OPENING-END-ROW)))

(fn opening? [row col]
  (or (left-opening? row col) (right-opening? row col)))

(fn perimeter? [row col]
  (or (= row 1) (= row GRID-H) (= col 1) (= col GRID-W)))

(fn terrain-kind-at [row col]
  (if (and (perimeter? row col) (not (opening? row col)))
      :wall
      (if (opening? row col) :opening :empty)))

(fn build-terrain []
  (var terrain {})
  (for [row 1 GRID-H]
    (for [col 1 GRID-W]
      (tset terrain (cell-key row col) (terrain-kind-at row col))))
  terrain)

(fn copy-terrain [terrain]
  (let [copy {}]
    (each [key kind (pairs terrain)]
      (tset copy key kind))
    copy))

(fn left-opening-cells []
  (var cells [])
  (for [row OPENING-START-ROW OPENING-END-ROW]
    (table.insert cells {:row row :col LEFT-COL}))
  cells)

(fn right-opening-cells []
  (var cells [])
  (for [row OPENING-START-ROW OPENING-END-ROW]
    (table.insert cells {:row row :col RIGHT-COL}))
  cells)

(fn pick-random-right-opening []
  (let [cells (right-opening-cells)]
    (. cells (math.random (# cells)))))

(fn pick-random-spawn-row []
  (. (pick-random-right-opening) :row))

(fn pixel-to-cell [px py]
  (let [col (+ 1 (math.floor (/ (- px BOARD-OX) CELL-SIZE)))
        row (+ 1 (math.floor (/ (- py BOARD-OY) CELL-SIZE)))]
    (when (and (>= row 1) (<= row GRID-H)
               (>= col 1) (<= col GRID-W))
      {:row row :col col})))

(fn create-game-world []
  (let [lux-world (create {:position [:x :y]
                          :grid-pos [:row :col]
                          :creep []})]
    {:world lux-world
     :terrain (build-terrain)
     :grid-w GRID-W
     :grid-h GRID-H}))

{:GRID-W GRID-W
 :GRID-H GRID-H
 :CELL-SIZE CELL-SIZE
 :BOARD-OX BOARD-OX
 :BOARD-OY BOARD-OY
 :OPENING-SIZE OPENING-SIZE
 :OPENING-START-ROW OPENING-START-ROW
 :OPENING-END-ROW OPENING-END-ROW
 :LEFT-COL LEFT-COL
 :RIGHT-COL RIGHT-COL
 :MAX-ESCAPES MAX-ESCAPES
 :CREEP-SPEED CREEP-SPEED
 :SPAWN-INTERVAL SPAWN-INTERVAL
 :cell-key cell-key
 :cell-bounds-at cell-bounds-at
 :cell-center-at cell-center-at
 :window-width window-width
 :window-height window-height
 :left-opening? left-opening?
 :right-opening? right-opening?
 :opening? opening?
 :perimeter? perimeter?
 :terrain-kind-at terrain-kind-at
 :build-terrain build-terrain
 :copy-terrain copy-terrain
 :left-opening-cells left-opening-cells
 :right-opening-cells right-opening-cells
 :pick-random-right-opening pick-random-right-opening
 :pick-random-spawn-row pick-random-spawn-row
 :pixel-to-cell pixel-to-cell
 :create create
 :create-entity create-entity
 :create-game-world create-game-world}
