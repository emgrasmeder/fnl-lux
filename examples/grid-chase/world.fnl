(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local create (. world-api :create))
(local create-entity (. world-api :create-entity))
(local run-updates (. world-api :run-updates))
(local pathfinding (require :pathfinding))

(local GRID-W 15)
(local GRID-H 15)
(local WALL-DENSITY 0.25)
(local CELL-SIZE 32)
(local BOARD-OX 40)
(local BOARD-OY 40)

(fn cell-key [row col] (pathfinding.pos-key row col))

(fn cell-bounds-at [row col]
  [(+ BOARD-OX (* (- col 1) CELL-SIZE))
   (+ BOARD-OY (* (- row 1) CELL-SIZE))
   CELL-SIZE
   CELL-SIZE])

(fn window-width [] (+ BOARD-OX (* GRID-W CELL-SIZE) BOARD-OX))
(fn window-height [] (+ BOARD-OY (* GRID-H CELL-SIZE) BOARD-OY))

(fn shuffle! [list]
  (for [i (# list) 2 -1]
    (let [j (math.random i)]
      (let [tmp (. list i)]
        (tset list i (. list j))
        (tset list j tmp))))
  list)

(fn all-coords [grid-w grid-h]
  (var coords [])
  (for [row 1 grid-h]
    (for [col 1 grid-w]
      (table.insert coords {:row row :col col})))
  coords)

(fn empty-terrain [grid-w grid-h]
  (var terrain {})
  (for [row 1 grid-h]
    (for [col 1 grid-w]
      (tset terrain (cell-key row col) :empty)))
  terrain)

(fn flood-fill-reachable [terrain grid-w grid-h start-row start-col]
  (let [start-key (cell-key start-row start-col)
        visited {}]
    (if (= (. terrain start-key) :wall)
        visited
        (do
          (var queue [{:row start-row :col start-col}])
          (var head 1)
          (tset visited start-key true)
          (while (<= head (# queue))
            (let [pos (. queue head)
                  row (. pos :row)
                  col (. pos :col)]
              (set head (+ head 1))
              (each [_ [dr dc] (ipairs [[-1 0] [1 0] [0 -1] [0 1]])]
                (let [nr (+ row dr)
                      nc (+ col dc)
                      key (cell-key nr nc)]
                  (when (and (>= nr 1) (<= nr grid-h)
                             (>= nc 1) (<= nc grid-w)
                             (not (. visited key))
                             (= (. terrain key) :empty))
                    (tset visited key true)
                    (table.insert queue {:row nr :col nc}))))))
          visited))))

(fn connected? [terrain grid-w grid-h]
  (let [reachable (flood-fill-reachable terrain grid-w grid-h 1 1)]
    (var empty-count 0)
    (var reachable-count 0)
    (for [row 1 grid-h]
      (for [col 1 grid-w]
        (when (= (. terrain (cell-key row col)) :empty)
          (set empty-count (+ empty-count 1))
          (when (. reachable (cell-key row col))
            (set reachable-count (+ reachable-count 1))))))
    (= empty-count reachable-count)))

(fn generate-terrain [grid-w grid-h wall-density]
  (let [terrain (empty-terrain grid-w grid-h)
        target-walls (math.floor (* grid-w grid-h wall-density))
        coords (shuffle! (all-coords grid-w grid-h))]
    (var placed 0)
    (each [_ coord (ipairs coords)]
      (when (< placed target-walls)
        (let [key (cell-key (. coord :row) (. coord :col))]
          (when (= (. terrain key) :empty)
            (tset terrain key :wall)
            (if (connected? terrain grid-w grid-h)
                (set placed (+ placed 1))
                (tset terrain key :empty))))))
    terrain))

(fn empty-cells [terrain grid-w grid-h]
  (var cells [])
  (for [row 1 grid-h]
    (for [col 1 grid-w]
      (when (= (. terrain (cell-key row col)) :empty)
        (table.insert cells {:row row :col col}))))
  cells)

(fn pick-random-cell [cells]
  (. cells (math.random (# cells))))

(fn pick-distinct-cells [cells count]
  (let [copy []
        _ (each [_ cell (ipairs cells)] (table.insert copy cell))]
    (shuffle! copy)
    [(. copy 1) (. copy 2)]))

(fn terrain-from-game [game]
  (let [world game.world
        cell-at game.cell-at
        get-table-by-id (. world-api :get-table-by-id)]
    (var terrain {})
    (each [key entity-id (pairs cell-at)]
      (let [components (get-table-by-id world entity-id)]
        (when components
          (tset terrain key (. components.terrain 1)))))
    terrain))

(fn apply-terrain-to-world! [world cell-at terrain]
  (let [updates {}]
    (each [key entity-id (pairs cell-at)]
      (tset updates entity-id [(. terrain key)]))
    (run-updates world {:terrain updates})))

(fn create-game-world []
  (let [terrain (generate-terrain GRID-W GRID-H WALL-DENSITY)
        world (create {:position [:row :col]
                       :terrain [:kind]
                       :cell-bounds [:x :y :w :h]
                       :actor [:kind]})
        cell-at {}]
    (for [row 1 GRID-H]
      (for [col 1 GRID-W]
        (let [[x y w h] (cell-bounds-at row col)
              kind (. terrain (cell-key row col))
              id (create-entity world [:position row col
                                       :terrain kind
                                       :cell-bounds x y w h])]
          (tset cell-at (cell-key row col) id))))
    (let [empties (empty-cells terrain GRID-W GRID-H)
          [monster-pos goal-pos] (pick-distinct-cells empties 2)
          monster-id (create-entity world [:position (. monster-pos :row) (. monster-pos :col)
                                           :actor :monster])
          goal-id (create-entity world [:position (. goal-pos :row) (. goal-pos :col)
                                       :actor :goal])]
      {:world world
       :cell-at cell-at
       :terrain terrain
       :monster-id monster-id
       :goal-id goal-id
       :grid-w GRID-W
       :grid-h GRID-H})))

(fn create-game-from-terrain [terrain monster-pos goal-pos]
  (let [world (create {:position [:row :col]
                       :terrain [:kind]
                       :cell-bounds [:x :y :w :h]
                       :actor [:kind]})
        cell-at {}]
    (for [row 1 GRID-H]
      (for [col 1 GRID-W]
        (let [[x y w h] (cell-bounds-at row col)
              kind (. terrain (cell-key row col))
              id (create-entity world [:position row col
                                       :terrain kind
                                       :cell-bounds x y w h])]
          (tset cell-at (cell-key row col) id))))
    (let [monster-id (create-entity world [:position (. monster-pos :row) (. monster-pos :col)
                                           :actor :monster])
          goal-id (create-entity world [:position (. goal-pos :row) (. goal-pos :col)
                                       :actor :goal])]
      {:world world
       :cell-at cell-at
       :terrain terrain
       :monster-id monster-id
       :goal-id goal-id
       :grid-w GRID-W
       :grid-h GRID-H})))

{:GRID-W GRID-W
 :GRID-H GRID-H
 :WALL-DENSITY WALL-DENSITY
 :CELL-SIZE CELL-SIZE
 :BOARD-OX BOARD-OX
 :BOARD-OY BOARD-OY
 :cell-key cell-key
 :cell-bounds-at cell-bounds-at
 :window-width window-width
 :window-height window-height
 :generate-terrain generate-terrain
 :connected? connected?
 :empty-cells empty-cells
 :terrain-from-game terrain-from-game
 :create-game-world create-game-world
 :create-game-from-terrain create-game-from-terrain
 :flood-fill-reachable flood-fill-reachable
 :shuffle! shuffle!}
