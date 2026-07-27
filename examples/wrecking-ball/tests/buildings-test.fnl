(import-macros
 {: deftest : testing : assert-is : assert-eq}
 :io.gitlab.andreyorst.fennel-test)

(local buildings (require :buildings))
(local c (require :constants))

(fn side-present? [footprints side]
  (var found false)
  (each [_ fp (ipairs footprints)]
    (when (= (. fp :side) side) (set found true)))
  found)

(fn count-targets [footprints]
  (var n 0)
  (each [_ fp (ipairs footprints)]
    (when (. fp :target?) (set n (+ n 1))))
  n)

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

(deftest both-sides-test
  (testing "at least one building per side"
    (math.randomseed 42)
    (let [{:footprints fps} (buildings.generate-buildings)]
      (assert-is (side-present? fps :left))
      (assert-is (side-present? fps :right)))))

(deftest target-building-test
  (testing "exactly one target footprint"
    (math.randomseed 42)
    (let [{:footprints fps :target-building-id tid} (buildings.generate-buildings)]
      (assert-eq (count-targets fps) 1)
      (assert-is tid)
      (each [_ fp (ipairs fps)]
        (when (. fp :target?)
          (assert-eq (. fp :building-id) tid)
          (assert-is (>= (. fp :r) 0.8)))))))

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

(deftest crane-reach-test
  (testing "crane reach covers worst-case building corner"
    (assert-is (>= (buildings.crane-max-reach) (buildings.worst-case-reach-needed)))))
