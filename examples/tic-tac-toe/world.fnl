(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local create (. world-api :create))
(local create-entity (. world-api :create-entity))

(local board-ox 60)
(local board-oy 80)
(local cell-size 120)

(fn cell-key [row col] (.. row "," col))

(fn cell-bounds-at [row col]
  [(+ board-ox (* (- col 1) cell-size))
   (+ board-oy (* (- row 1) cell-size))
   cell-size
   cell-size])

(fn create-game-world []
  (let [world (create {:position [:row :col]
                       :mark [:player]
                       :cell-bounds [:x :y :w :h]})
        cell-at {}]
    (for [row 1 3]
      (for [col 1 3]
        (let [[x y w h] (cell-bounds-at row col)
              ;; :empty keeps the mark pool dense so Lux run-updates can find cells
              id (create-entity world [:position row col
                                       :mark :empty
                                       :cell-bounds x y w h])]
          (tset cell-at (cell-key row col) id))))
    {:world world :cell-at cell-at}))

{:board-ox board-ox
 :board-oy board-oy
 :cell-size cell-size
 :create-game-world create-game-world
 :cell-key cell-key
 :cell-bounds-at cell-bounds-at}
