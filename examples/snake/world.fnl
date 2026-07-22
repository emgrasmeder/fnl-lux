(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local create (. world-api :create))
(local create-entity (. world-api :create-entity))
(local grid (require :shared.grid))
(local util (require :shared.util))

(local GRID-W 20)
(local GRID-H 20)
(local CELL-SIZE 24)
(local BOARD-OX 40)
(local BOARD-OY 40)

(local DIRECTIONS [:up :down :left :right])

(fn cell-key [row col] (grid.pos-key row col))

(fn cell-bounds-at [row col]
  (grid.cell-bounds-at BOARD-OX BOARD-OY CELL-SIZE row col))

(fn window-width [] (grid.window-width BOARD-OX GRID-W CELL-SIZE))
(fn window-height [] (grid.window-height BOARD-OY GRID-H CELL-SIZE))

(fn border? [row col]
  (or (= row 1) (= row GRID-H) (= col 1) (= col GRID-H)))

(fn playable? [row col]
  (and (>= row 2) (<= row (- GRID-H 1))
       (>= col 2) (<= col (- GRID-W 1))))

(fn terrain-at [row col]
  (if (border? row col) :wall :empty))

(fn all-playable-coords []
  (var coords [])
  (for [row 2 (- GRID-H 1)]
    (for [col 2 (- GRID-W 1)]
      (table.insert coords {:row row :col col})))
  coords)

(fn occupied-by-body? [body row col]
  (var found false)
  (each [_ segment (ipairs body)]
    (when (util.positions-equal? segment {:row row :col col})
      (set found true)))
  found)

(fn pick-random-direction []
  (. DIRECTIONS (math.random (# DIRECTIONS))))

(fn direction-delta [direction]
  (case direction
    :up [-1 0]
    :down [1 0]
    :left [0 -1]
    :right [0 1]))

(fn body-behind-head [head-row head-col direction]
  (let [[dr dc] (direction-delta direction)
        tail-row (- head-row dr)
        tail-col (- head-col dc)
        mid-row (- tail-row dr)
        mid-col (- tail-col dc)]
    [{:row head-row :col head-col}
     {:row tail-row :col tail-col}
     {:row mid-row :col mid-col}]))

(fn pick-food-position [body]
  (let [candidates []]
    (each [_ coord (ipairs (all-playable-coords))]
      (when (not (occupied-by-body? body (. coord :row) (. coord :col)))
        (table.insert candidates coord)))
    (when (> (# candidates) 0)
      (. candidates (math.random (# candidates))))))

(fn build-grid-world []
  (grid.build-cell-grid
   create create-entity
   {:position [:row :col]
    :terrain [:kind]
    :cell-bounds [:x :y :w :h]
    :actor [:kind]
    :direction [:dir]}
   GRID-W GRID-H
   (fn [world _create-entity row col]
     (let [[x y w h] (cell-bounds-at row col)
           kind (terrain-at row col)]
       (create-entity world [:position row col
                            :terrain kind
                            :cell-bounds x y w h])))))

(fn create-game-from-state [body food-pos direction]
  (let [result (build-grid-world)
        world (. result :world)
        cell-at (. result :cell-at)
        head (. body 1)
        player-id (create-entity world [:position (. head :row) (. head :col)
                                        :actor :player
                                        :direction direction])
        food-id (create-entity world [:position (. food-pos :row) (. food-pos :col)
                                      :actor :food])]
    {:world world
     :cell-at cell-at
     :player-id player-id
     :food-id food-id
     :grid-w GRID-W
     :grid-h GRID-H
     :initial-body body
     :initial-direction direction}))

(fn create-game-world []
  (let [direction (pick-random-direction)
        head-row 11
        head-col 11
        body (body-behind-head head-row head-col direction)
        food-pos (or (pick-food-position body) {:row 2 :col 2})]
    (create-game-from-state body food-pos direction)))

{:GRID-W GRID-W
 :GRID-H GRID-H
 :CELL-SIZE CELL-SIZE
 :BOARD-OX BOARD-OX
 :BOARD-OY BOARD-OY
 :cell-key cell-key
 :cell-bounds-at cell-bounds-at
 :window-width window-width
 :window-height window-height
 :border? border?
 :playable? playable?
 :terrain-at terrain-at
 :positions-equal? util.positions-equal?
 :occupied-by-body? occupied-by-body?
 :pick-random-direction pick-random-direction
 :direction-delta direction-delta
 :body-behind-head body-behind-head
 :pick-food-position pick-food-position
 :create-game-world create-game-world
 :create-game-from-state create-game-from-state}
