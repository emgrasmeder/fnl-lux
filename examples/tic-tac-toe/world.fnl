(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local create (. world-api :create))
(local create-entity (. world-api :create-entity))
(local grid (require :shared.grid))

(local board-ox 60)
(local board-oy 80)
(local cell-size 120)

(fn cell-key [row col] (grid.pos-key row col))

(fn cell-bounds-at [row col]
  (grid.cell-bounds-at board-ox board-oy cell-size row col))

(fn create-game-world []
  (let [result (grid.build-cell-grid
                create create-entity
                {:position [:row :col]
                 :mark [:player]
                 :cell-bounds [:x :y :w :h]}
                3 3
                (fn [world _create-entity row col]
                  (let [[x y w h] (cell-bounds-at row col)]
                    ;; :empty keeps the mark pool dense so Lux run-updates can find cells
                    (create-entity world [:position row col
                                         :mark :empty
                                         :cell-bounds x y w h]))))
        world (. result :world)
        cell-at (. result :cell-at)]
    {:world world :cell-at cell-at}))

{:board-ox board-ox
 :board-oy board-oy
 :cell-size cell-size
 :create-game-world create-game-world
 :cell-key cell-key
 :cell-bounds-at cell-bounds-at}
