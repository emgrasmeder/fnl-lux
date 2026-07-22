(import-macros
 {: deftest : assert-eq : assert-is : assert-not : testing}
 :io.gitlab.andreyorst.fennel-test)

(local pathfinding (require :pathfinding))

(fn empty-terrain [grid-w grid-h]
  (var terrain {})
  (for [row 1 grid-h]
    (for [col 1 grid-w]
      (tset terrain (pathfinding.pos-key row col) :empty)))
  terrain)

(fn terrain-with-wall [grid-w grid-h wall-cells]
  (let [terrain (empty-terrain grid-w grid-h)]
    (each [_ cell (ipairs wall-cells)]
      (tset terrain (pathfinding.pos-key (. cell :row) (. cell :col)) :wall))
    terrain))

(deftest manhattan-test
  (testing "manhattan distance"
    (assert-eq 4 (pathfinding.manhattan {:row 1 :col 1} {:row 3 :col 3}))
    (assert-eq 0 (pathfinding.manhattan {:row 2 :col 2} {:row 2 :col 2}))))

(deftest straight-line-test
  (testing "straight horizontal path"
    (let [terrain (empty-terrain 5 5)
          path (pathfinding.find-path terrain {:row 1 :col 1} {:row 1 :col 4} 5 5)]
      (assert-is path)
      (assert-eq 3 (# path))
      (assert-eq 1 (. path 1 :row))
      (assert-eq 2 (. path 1 :col))
      (assert-eq 1 (. path 3 :row))
      (assert-eq 4 (. path 3 :col)))))

(deftest around-wall-test
  (testing "path routes around a wall"
    (let [terrain (terrain-with-wall 5 5 [{:row 1 :col 3}
                                          {:row 2 :col 3}
                                          {:row 3 :col 3}])
          path (pathfinding.find-path terrain {:row 1 :col 1} {:row 1 :col 5} 5 5)]
      (assert-is path)
      (each [_ step (ipairs path)]
        (assert-not (= (. terrain (pathfinding.pos-key (. step :row) (. step :col))) :wall))))))

(deftest no-path-test
  (testing "unreachable goal returns nil"
    (var walls [])
    (for [col 1 5]
      (table.insert walls {:row 2 :col col}))
    (let [terrain (terrain-with-wall 5 5 walls)
          path (pathfinding.find-path terrain {:row 1 :col 1} {:row 5 :col 5} 5 5)]
      (assert-not path))))

(deftest same-cell-test
  (testing "start equals goal returns empty path"
    (let [terrain (empty-terrain 5 5)
          path (pathfinding.find-path terrain {:row 2 :col 2} {:row 2 :col 2} 5 5)]
      (assert-is path)
      (assert-eq 0 (# path)))))

(deftest start-on-wall-test
  (testing "start on wall returns nil"
    (let [terrain (terrain-with-wall 5 5 [{:row 1 :col 1}])
          path (pathfinding.find-path terrain {:row 1 :col 1} {:row 1 :col 2} 5 5)]
      (assert-not path))))
