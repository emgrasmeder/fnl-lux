(import-macros
 {: deftest : assert-is : testing}
 :io.gitlab.andreyorst.fennel-test)

(local layout (require :layout))
(local systems (require :systems))
(local world (require :world))

(deftest segment-rects-count-test
  (testing "segment-rects returns one rect per body segment"
    (let [rects (layout.segment-rects [{:row 11 :col 11} {:row 11 :col 10} {:row 11 :col 9}])]
      (assert-is (= 3 (# rects))))))

(deftest segment-rects-position-test
  (testing "segment-rects uses cell-bounds-at"
    (let [[[x y w h]] (layout.segment-rects [{:row 2 :col 3}])
          [ex ey ew eh] (world.cell-bounds-at 2 3)]
      (assert-is (= ex x))
      (assert-is (= ey y))
      (assert-is (= ew w))
      (assert-is (= eh h)))))

(deftest food-rect-test
  (testing "food-rect maps food position to pixels"
    (let [food {:row 5 :col 7}
          [x y w h] (layout.food-rect food)
          [ex ey ew eh] (world.cell-bounds-at 5 7)]
      (assert-is (= ex x))
      (assert-is (= ey y))
      (assert-is (= ew w))
      (assert-is (= eh h)))))

(deftest food-rect-nil-test
  (testing "food-rect returns nil without food"
    (assert-is (not (layout.food-rect nil)))))

(deftest overlay-text-ui-test
  (testing "overlay helper matches systems"
    (assert-is (= "PAUSED" (systems.overlay-text {:phase :paused})))
    (assert-is (= "Game Over — press R" (systems.overlay-text {:phase :ended})))))

(deftest position-rect-test
  (testing "position-rect delegates to cell-bounds-at"
    (let [[x y w h] (layout.position-rect 10 10)
          [ex ey ew eh] (world.cell-bounds-at 10 10)]
      (assert-is (= ex x))
      (assert-is (= ey y))
      (assert-is (= ew w))
      (assert-is (= eh h)))))
