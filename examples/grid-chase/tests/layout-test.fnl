(import-macros
 {: deftest : assert-eq : assert-is : testing}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))

(deftest cell-bounds-test
  (testing "cell-bounds-at pixel math"
    (let [[x y w h] (world.cell-bounds-at 1 1)]
      (assert-eq world.BOARD-OX x)
      (assert-eq world.BOARD-OY y)
      (assert-eq world.CELL-SIZE w)
      (assert-eq world.CELL-SIZE h))
    (let [[x y] (world.cell-bounds-at 2 3)]
      (assert-eq (+ world.BOARD-OX (* 2 world.CELL-SIZE)) x)
      (assert-eq (+ world.BOARD-OY (* 1 world.CELL-SIZE)) y))))

(deftest window-size-test
  (testing "window dimensions from grid"
    (assert-eq (+ (* 2 world.BOARD-OX) (* world.GRID-W world.CELL-SIZE))
               (world.window-width))
    (assert-eq (+ (* 2 world.BOARD-OY) (* world.GRID-H world.CELL-SIZE))
               (world.window-height))))

(deftest cell-key-roundtrip-test
  (testing "cell-key round-trip"
    (for [row 1 5]
      (for [col 1 5]
        (assert-eq (.. row "," col) (world.cell-key row col))))))
