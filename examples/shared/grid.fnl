(fn pos-key [row col]
  (.. row "," col))

(fn cell-bounds-at [board-ox board-oy cell-size row col]
  [(+ board-ox (* (- col 1) cell-size))
   (+ board-oy (* (- row 1) cell-size))
   cell-size
   cell-size])

(fn window-width [board-ox grid-w cell-size]
  (+ board-ox (* grid-w cell-size) board-ox))

(fn window-height [board-oy grid-h cell-size]
  (+ board-oy (* grid-h cell-size) board-oy))

(fn build-cell-grid [create create-entity component-spec grid-w grid-h spawn-cell!]
  (let [world (create component-spec)
        cell-at {}]
    (for [row 1 grid-h]
      (for [col 1 grid-w]
        (let [entity-id (spawn-cell! world create-entity row col)]
          (tset cell-at (pos-key row col) entity-id))))
    {:world world :cell-at cell-at}))

{:pos-key pos-key
 :cell-bounds-at cell-bounds-at
 :window-width window-width
 :window-height window-height
 :build-cell-grid build-cell-grid}
