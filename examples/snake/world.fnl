(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local create (. world-api :create))
(local create-entity (. world-api :create-entity))

(local GRID-W 20)
(local GRID-H 20)
(local CELL-SIZE 24)
(local BOARD-OX 40)
(local BOARD-OY 40)

(local DIRECTIONS [:up :down :left :right])

(fn cell-key [row col] (.. row "," col))

(fn cell-bounds-at [row col]
  [(+ BOARD-OX (* (- col 1) CELL-SIZE))
   (+ BOARD-OY (* (- row 1) CELL-SIZE))
   CELL-SIZE
   CELL-SIZE])

(fn window-width [] (+ BOARD-OX (* GRID-W CELL-SIZE) BOARD-OX))
(fn window-height [] (+ BOARD-OY (* GRID-H CELL-SIZE) BOARD-OY))

(fn border? [row col]
  (or (= row 1) (= row GRID-H) (= col 1) (= col GRID-H)))

(fn playable? [row col]
  (and (>= row 2) (<= row (- GRID-H 1))
       (>= col 2) (<= col (- GRID-W 1))))

(fn terrain-at [row col]
  (if (border? row col) :wall :empty))

(fn shuffle! [list]
  (for [i (# list) 2 -1]
    (let [j (math.random i)]
      (let [tmp (. list i)]
        (tset list i (. list j))
        (tset list j tmp))))
  list)

(fn all-playable-coords []
  (var coords [])
  (for [row 2 (- GRID-H 1)]
    (for [col 2 (- GRID-W 1)]
      (table.insert coords {:row row :col col})))
  coords)

(fn positions-equal? [a b]
  (and a b (= (. a :row) (. b :row)) (= (. a :col) (. b :col))))

(fn occupied-by-body? [body row col]
  (var found false)
  (each [_ segment (ipairs body)]
    (when (positions-equal? segment {:row row :col col})
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
  (let [world (create {:position [:row :col]
                       :terrain [:kind]
                       :cell-bounds [:x :y :w :h]
                       :actor [:kind]
                       :direction [:dir]})
        cell-at {}]
    (for [row 1 GRID-H]
      (for [col 1 GRID-W]
        (let [[x y w h] (cell-bounds-at row col)
              kind (terrain-at row col)
              id (create-entity world [:position row col
                                       :terrain kind
                                       :cell-bounds x y w h])]
          (tset cell-at (cell-key row col) id))))
    {:world world :cell-at cell-at}))

(fn create-game-from-state [body food-pos direction]
  (let [{:world world :cell-at cell-at} (build-grid-world)
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
 :positions-equal? positions-equal?
 :occupied-by-body? occupied-by-body?
 :pick-random-direction pick-random-direction
 :direction-delta direction-delta
 :body-behind-head body-behind-head
 :pick-food-position pick-food-position
 :create-game-world create-game-world
 :create-game-from-state create-game-from-state}
