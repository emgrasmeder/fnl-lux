(fn pos-key [row col] (.. row "," col))

(fn manhattan [a b]
  (+ (math.abs (- (. a :row) (. b :row)))
     (math.abs (- (. a :col) (. b :col)))))

(fn terrain-at [terrain row col]
  (let [key (pos-key row col)]
    (or (. terrain key) :wall)))

(fn passable? [terrain row col]
  (= (terrain-at terrain row col) :empty))

(fn neighbors [terrain row col grid-w grid-h]
  (var result [])
  (each [_ [dr dc] (ipairs [[-1 0] [1 0] [0 -1] [0 1]])]
    (let [nr (+ row dr)
          nc (+ col dc)]
      (when (and (>= nr 1) (<= nr grid-h)
                 (>= nc 1) (<= nc grid-w)
                 (passable? terrain nr nc))
        (table.insert result {:row nr :col nc}))))
  result)

(fn reconstruct-path [came-from current]
  (var path [])
  (var pos current)
  (while pos
    (table.insert path 1 pos)
    (set pos (. came-from (pos-key (. pos :row) (. pos :col)))))
  (table.remove path 1)
  path)

(fn lowest-f-score [open-set f-score]
  (var best nil)
  (var best-score nil)
  (each [_ pos (ipairs open-set)]
    (let [key (pos-key (. pos :row) (. pos :col))
          score (. f-score key)]
      (when (or (not best-score) (< score best-score))
        (set best pos)
        (set best-score score))))
  best)

(fn remove-from-open [open-set target]
  (var result [])
  (each [_ pos (ipairs open-set)]
    (when (not (and (= (. pos :row) (. target :row))
                    (= (. pos :col) (. target :col))))
      (table.insert result pos)))
  result)

(fn in-open? [open-set pos]
  (var found false)
  (each [_ candidate (ipairs open-set)]
    (when (and (= (. candidate :row) (. pos :row))
               (= (. candidate :col) (. pos :col)))
      (set found true)))
  found)

(fn find-path [terrain start goal grid-w grid-h]
  (when (not (and (passable? terrain (. start :row) (. start :col))
                  (passable? terrain (. goal :row) (. goal :col))))
    (lua "return nil"))
  (when (and (= (. start :row) (. goal :row))
             (= (. start :col) (. goal :col)))
    (lua "return {}"))
  (var open-set [start])
  (var came-from {})
  (var g-score {(pos-key (. start :row) (. start :col)) 0})
  (var f-score {(pos-key (. start :row) (. start :col)) (manhattan start goal)})
  (var done false)
  (var result nil)
  (while (and (not done) (> (# open-set) 0))
    (let [current (lowest-f-score open-set f-score)
          current-key (pos-key (. current :row) (. current :col))]
      (if (and (= (. current :row) (. goal :row))
               (= (. current :col) (. goal :col)))
          (do
            (set result (reconstruct-path came-from current))
            (set done true))
          (do
            (set open-set (remove-from-open open-set current))
            (each [_ neighbor (ipairs (neighbors terrain (. current :row) (. current :col) grid-w grid-h))]
              (let [neighbor-key (pos-key (. neighbor :row) (. neighbor :col))
                    tentative (+ (. g-score current-key) 1)]
                (when (or (not (. g-score neighbor-key))
                          (< tentative (. g-score neighbor-key)))
                  (tset came-from neighbor-key current)
                  (tset g-score neighbor-key tentative)
                  (tset f-score neighbor-key (+ tentative (manhattan neighbor goal)))
                  (when (not (in-open? open-set neighbor))
                    (table.insert open-set neighbor)))))))))
  result)

{:pos-key pos-key
 :manhattan manhattan
 :passable? passable?
 :find-path find-path}
