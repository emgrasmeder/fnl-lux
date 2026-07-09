(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local create (. world-api :create))
(local create-entity (. world-api :create-entity))

(fn cell-key [row col] (.. row "," col))

(fn create-game-world []
  (let [world (create {:position [:row :col]
                      :mark [:player]})
        cell-at {}]
    (for [row 1 3]
      (for [col 1 3]
        ;; :empty keeps the mark pool dense so Lux run-updates can find cells
        (let [id (create-entity world [:position row col :mark :empty])]
          (tset cell-at (cell-key row col) id))))
    {:world world :cell-at cell-at}))

{:create-game-world create-game-world
 :cell-key cell-key}
