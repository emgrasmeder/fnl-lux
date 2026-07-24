(import-macros
 {: deftest : testing : assert-is : assert-eq}
 :io.gitlab.andreyorst.fennel-test)

(local buildings (require :buildings))
(local c (require :constants))

(deftest generate-buildings-test
  (testing "buildings are solid rectangles within caps"
    (math.randomseed 42)
    (let [{:footprints fps :spawns spawns} (buildings.generate-buildings)]
      (assert-is (> (# fps) 0))
      (assert-is (> (# spawns) 0))
      (assert-is (<= (# spawns) c.MAX-BRICKS))
      (each [_ fp (ipairs fps)]
        (assert-is (>= (. fp :w-bricks) c.MIN-BUILDING-W-BRICKS))
        (assert-is (>= (. fp :h-bricks) c.MIN-BUILDING-H-BRICKS)))
      (assert-eq (# spawns) (buildings.count-bricks fps)))))

(deftest exclusion-zone-test
  (testing "footprints avoid crane exclusion"
    (math.randomseed 99)
    (let [{:footprints fps} (buildings.generate-buildings)]
      (each [_ fp (ipairs fps)]
        (let [px (buildings.footprint-pixels fp)]
          (assert-is
           (not (buildings.in-exclusion-zone? (. px :x) (. px :y) (. px :w) (. px :h)))))))))

(deftest footprint-on-ground-test
  (testing "building bottoms sit on ground line"
    (math.randomseed 42)
    (let [{:footprints fps} (buildings.generate-buildings)]
      (each [_ fp (ipairs fps)]
        (let [px (buildings.footprint-pixels fp)
              bottom (+ (. px :y) (. px :h))]
          (assert-eq bottom c.GROUND-Y))))))
