(local world-mod (require :world))

(local NEIGHBORS [[-1 0] [1 0] [0 -1] [0 1]])

(fn walkable? [terrain key]
  (let [kind (. terrain key)]
    (or (= kind :empty) (= kind :opening))))

(fn goal-key-set [goal-cells]
  (let [keys {}]
    (each [_ cell (ipairs goal-cells)]
      (tset keys (world-mod.cell-key (. cell :row) (. cell :col)) true))
    keys))

(fn reconstruct-path [came-from start-row start-col goal-row goal-col]
  (var path [{:row goal-row :col goal-col}])
  (var row goal-row)
  (var col goal-col)
  (while (or (not= row start-row) (not= col start-col))
    (let [parent (. came-from (world-mod.cell-key row col))]
      (set row (. parent :row))
      (set col (. parent :col))
      (table.insert path 1 {:row row :col col})))
  path)

(fn shortest-path [terrain grid-w grid-h start-row start-col goal-cells]
  (let [start-key (world-mod.cell-key start-row start-col)
        goals (goal-key-set goal-cells)]
    (if (. goals start-key)
        [{:row start-row :col start-col}]
        (if (not (walkable? terrain start-key))
            nil
            (do
              (var queue [{:row start-row :col start-col}])
              (var came-from {})
              (var visited {})
              (var found nil)
              (var head 1)
              (tset visited start-key true)
              (while (and (<= head (# queue)) (not found))
                (let [pos (. queue head)]
                  (set head (+ head 1))
                  (each [_ [dr dc] (ipairs NEIGHBORS)]
                    (let [nr (+ (. pos :row) dr)
                          nc (+ (. pos :col) dc)
                          key (world-mod.cell-key nr nc)]
                      (when (and (>= nr 1) (<= nr grid-h)
                                 (>= nc 1) (<= nc grid-w)
                                 (not (. visited key))
                                 (walkable? terrain key))
                        (tset visited key true)
                        (tset came-from key {:row (. pos :row) :col (. pos :col)})
                        (if (. goals key)
                            (set found {:row nr :col nc})
                            (table.insert queue {:row nr :col nc})))))))
              (when found
                (reconstruct-path came-from start-row start-col (. found :row) (. found :col))))))))

(fn portal-connected? [terrain grid-w grid-h right-openings left-openings]
  (var connected false)
  (each [_ start (ipairs right-openings)]
    (when (not connected)
      (when (shortest-path terrain grid-w grid-h (. start :row) (. start :col) left-openings)
        (set connected true))))
  connected)

(fn path-to-exit [terrain grid-w grid-h start-row start-col left-openings]
  (shortest-path terrain grid-w grid-h start-row start-col left-openings))

(fn terrain-with-tower [terrain row col place?]
  (let [copy (world-mod.copy-terrain terrain)
        key (world-mod.cell-key row col)]
    (tset copy key (if place? :tower :empty))
    copy))

(fn creep-at? [creep-cells row col]
  (var found false)
  (each [_ cell (ipairs creep-cells)]
    (when (and (= (. cell :row) row) (= (. cell :col) col))
      (set found true)))
  found)

(fn connectivity-ok? [terrain grid-w grid-h right-openings left-openings creep-cells]
  (if (not (portal-connected? terrain grid-w grid-h right-openings left-openings))
      false
      (do
        (var ok true)
        (each [_ cell (ipairs creep-cells)]
          (when (not (path-to-exit terrain grid-w grid-h
                                   (. cell :row) (. cell :col) left-openings))
            (set ok false)))
        ok)))

(fn placement-valid? [terrain grid-w grid-h row col left-openings right-openings
                       creep-cells place?]
  (let [key (world-mod.cell-key row col)
        kind (. terrain key)]
    (if place?
        (and (= kind :empty)
             (not (world-mod.opening? row col))
             (not (creep-at? creep-cells row col))
             (connectivity-ok? (terrain-with-tower terrain row col true)
                               grid-w grid-h right-openings left-openings creep-cells))
        (and (= kind :tower)
             (connectivity-ok? (terrain-with-tower terrain row col false)
                               grid-w grid-h right-openings left-openings creep-cells)))))

{:walkable? walkable?
 :shortest-path shortest-path
 :portal-connected? portal-connected?
 :path-to-exit path-to-exit
 :terrain-with-tower terrain-with-tower
 :placement-valid? placement-valid?}
