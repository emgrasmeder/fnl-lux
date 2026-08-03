(import-macros
 {: deftest : assert-eq : assert-is : assert-not : testing}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local pathfinding (require :pathfinding))

(fn fresh-terrain []
  (world.build-terrain))

(deftest portal-connected-initial-test
  (testing "open board connects right to left openings"
    (let [terrain (fresh-terrain)]
      (assert-is (pathfinding.portal-connected? terrain world.GRID-W world.GRID-H
                                                (world.right-opening-cells)
                                                (world.left-opening-cells))))))

(deftest seal-rejected-test
  (testing "vertical wall across middle blocks all paths"
    (let [terrain (fresh-terrain)]
      (for [row 2 (- world.GRID-H 1)]
        (tset terrain (world.cell-key row 15) :tower))
      (assert-not (pathfinding.portal-connected? terrain world.GRID-W world.GRID-H
                                                 (world.right-opening-cells)
                                                 (world.left-opening-cells))))))

(deftest shortest-path-test
  (testing "path from right opening reaches left opening"
    (let [terrain (fresh-terrain)
          start (world.pick-random-right-opening)
          path (pathfinding.shortest-path terrain world.GRID-W world.GRID-H
                                          (. start :row) (. start :col)
                                          (world.left-opening-cells))]
      (assert-is path)
      (assert-is (> (# path) 0))
      (let [first (. path 1)
            last (. path (# path))]
        (assert-eq (. start :row) (. first :row))
        (assert-eq (. start :col) (. first :col))
        (assert-is (world.left-opening? (. last :row) (. last :col)))))))

(deftest placement-valid-test
  (testing "cannot place on opening or wall"
    (let [terrain (fresh-terrain)
          left (world.left-opening-cells)
          right (world.right-opening-cells)]
      (assert-not (pathfinding.placement-valid? terrain world.GRID-W world.GRID-H
                                                1 1 left right [] true))
      (assert-not (pathfinding.placement-valid? terrain world.GRID-W world.GRID-H
                                                15 1 left right [] true))
      (assert-is (pathfinding.placement-valid? terrain world.GRID-W world.GRID-H
                                               15 15 left right [] true)))))

(deftest placement-seal-test
  (testing "cannot place tower that seals portals"
    (let [terrain (fresh-terrain)
          left (world.left-opening-cells)
          right (world.right-opening-cells)]
      (for [row 2 (- world.GRID-H 1)]
        (when (not= row 15)
          (tset terrain (world.cell-key row 15) :tower)))
      (assert-not (pathfinding.placement-valid? terrain world.GRID-W world.GRID-H
                                               15 15 left right [] true)))))

(deftest stranded-creep-rejected-test
  (testing "cannot trap an existing creep without a path"
    (let [terrain (fresh-terrain)
          left (world.left-opening-cells)
          right (world.right-opening-cells)
          creep [{:row 15 :col 15}]]
      (tset terrain (world.cell-key 14 15) :tower)
      (tset terrain (world.cell-key 16 15) :tower)
      (tset terrain (world.cell-key 15 14) :tower)
      (assert-not (pathfinding.placement-valid? terrain world.GRID-W world.GRID-H
                                               15 16 left right creep true)))))
