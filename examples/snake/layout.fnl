(local world-mod (require :world))

(fn position-rect [row col]
  (world-mod.cell-bounds-at row col))

(fn segment-rects [body]
  (var rects [])
  (each [_ segment (ipairs body)]
    (table.insert rects (position-rect (. segment :row) (. segment :col))))
  rects)

(fn food-rect [food-pos]
  (when food-pos
    (position-rect (. food-pos :row) (. food-pos :col))))

{:position-rect position-rect
 :segment-rects segment-rects
 :food-rect food-rect}
