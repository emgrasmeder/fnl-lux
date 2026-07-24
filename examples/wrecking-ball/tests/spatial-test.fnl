(import-macros
 {: deftest : testing : assert-eq : assert-is}
 :io.gitlab.andreyorst.fennel-test)

(local spatial (require :spatial))
(local c (require :constants))

(deftest brick-pairs-test
  (testing "entities in same cell produce pairs"
    (let [grid {}]
      (spatial.insert-entity! grid c.SPATIAL-CELL-SIZE 1 10 10)
      (spatial.insert-entity! grid c.SPATIAL-CELL-SIZE 2 12 11)
      (spatial.insert-entity! grid c.SPATIAL-CELL-SIZE 3 200 200)
      (let [pairs (spatial.brick-pairs grid)]
        (assert-eq 1 (# pairs))
        (assert-is (or (and (= (. (. pairs 1) 1) 1) (= (. (. pairs 1) 2) 2))
                         (and (= (. (. pairs 1) 1) 2) (= (. (. pairs 1) 2) 1))))))))

(deftest query-near-test
  (testing "query finds co-located ids"
    (let [grid {}]
      (spatial.insert-entity! grid c.SPATIAL-CELL-SIZE 5 32 32)
      (spatial.insert-entity! grid c.SPATIAL-CELL-SIZE 6 34 33)
      (let [near (spatial.query-near grid c.SPATIAL-CELL-SIZE 32 32)]
        (assert-is (>= (# near) 1))))))
