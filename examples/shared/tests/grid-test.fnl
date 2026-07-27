(import-macros
 {: deftest : assert-eq : assert-is : testing}
 :io.gitlab.andreyorst.fennel-test)

(local grid (require :shared.grid))

(deftest cell-bounds-test
  (testing "cell-bounds-at offsets grid"
    (let [[x y w h] (grid.cell-bounds-at 10 20 30 2 3)]
      (assert-eq 70 x)
      (assert-eq 50 y)
      (assert-eq 30 w)
      (assert-eq 30 h))))

(deftest window-size-test
  (testing "window dimensions include margins"
    (assert-eq 140 (grid.window-width 10 4 30))
    (assert-eq 150 (grid.window-height 15 3 40))))

(deftest pos-key-test
  (testing "pos-key joins row and col"
    (assert-eq "2,5" (grid.pos-key 2 5))))
