(import-macros
 {: deftest : testing : assert-is : assert-eq : assert-not}
 :io.gitlab.andreyorst.fennel-test)

(local c (require :constants))
(local terrain (require :terrain))

(deftest pane-valid-test
  (testing "generated pane respects step and slope limits"
    (math.randomseed 42)
    (for [i 1 20]
      (let [pane (terrain.generate-pane 0 c.FLOOR_BASE)]
        (assert-is (terrain.pane-valid? pane))))))

(deftest pane-stitch-test
  (testing "consecutive panes share boundary height"
    (math.randomseed 7)
    (let [p0 (terrain.generate-pane 0 c.FLOOR_BASE)
          p1 (terrain.generate-pane 1 (. p0 :exit-y))]
      (assert-eq (. p0 :exit-y) (. p1 :entry-y))
      (assert-eq (. p0 :end-x) (. p1 :start-x)))))

(deftest segment-count-test
  (testing "pane has terrain segments"
    (let [pane (terrain.generate-pane 0 c.FLOOR_BASE)]
      (assert-is (> (# pane.segments) 0)))))

(deftest clamp-dy-test
  (testing "clamp-dy enforces max step"
    (let [dx c.SAMPLE_DX
          max-dy (terrain.max-dy-for-step dx)]
      (assert-eq max-dy (terrain.clamp-dy (+ max-dy 100) dx))
      (assert-eq (- max-dy) (terrain.clamp-dy (- (+ max-dy 100)) dx)))))
