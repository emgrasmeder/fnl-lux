(local c (require :constants))

(fn cell-key [cx cy]
  (.. cx "," cy))

(fn cell-coord [v cell-size]
  (math.floor (/ v cell-size)))

(fn clear-grid! [grid]
  (each [k _ (pairs grid)]
    (tset grid k nil)))

(fn insert-entity! [grid cell-size id x y]
  (let [cx (cell-coord x cell-size)
        cy (cell-coord y cell-size)
        key (cell-key cx cy)]
    (when (not (. grid key))
      (tset grid key []))
    (table.insert (. grid key) id)))

(fn rebuild! [grid cell-size ids get-pos]
  (clear-grid! grid)
  (each [_ id (ipairs ids)]
    (let [pos (get-pos id)]
      (when pos
        (insert-entity! grid cell-size id (. pos :x) (. pos :y))))))

(fn neighbor-cells [x y cell-size]
  (let [cx (cell-coord x cell-size)
        cy (cell-coord y cell-size)
        cells []]
    (for [dx -1 1]
      (for [dy -1 1]
        (table.insert cells (cell-key (+ cx dx) (+ cy dy)))))
    cells))

(fn query-near [grid cell-size x y]
  (let [seen {}
        result []]
    (each [_ key (ipairs (neighbor-cells x y cell-size))]
      (each [_ id (ipairs (or (. grid key) []))]
        (when (not (. seen id))
          (tset seen id true)
          (table.insert result id))))
    result))

(fn unique-pairs [ids-a ids-b skip-same?]
  (let [pairs []]
    (for [i 1 (# ids-a)]
      (for [j 1 (# ids-b)]
        (let [a (. ids-a i)
              b (. ids-b j)]
          (when (or (not skip-same?) (~= a b))
            (when (or (not skip-same?) (< a b))
              (table.insert pairs [a b]))))))
    pairs))

(fn brick-pairs [grid]
  (let [result []
        seen {}]
    (each [_ cell-ids (pairs grid)]
      (for [i 1 (# cell-ids)]
        (for [j (+ i 1) (# cell-ids)]
          (let [a (. cell-ids i)
                b (. cell-ids j)
                pair-key (if (< a b) (.. a ":" b) (.. b ":" a))]
            (when (not (. seen pair-key))
              (tset seen pair-key true)
              (table.insert result [a b]))))))
    result))

{:clear-grid! clear-grid!
 :rebuild! rebuild!
 :insert-entity! insert-entity!
 :query-near query-near
 :unique-pairs unique-pairs
 :brick-pairs brick-pairs
 :cell-coord cell-coord
 :cell-key cell-key}
