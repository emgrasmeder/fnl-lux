(import-macros
 {: deftest : assert-eq : assert-is : testing}
 :io.gitlab.andreyorst.fennel-test)

(local util (require :shared.util))

(deftest point-in-rect-test
  (testing "point-in-rect?"
    (assert-is (util.point-in-rect? 10 10 0 0 20 20))
    (assert-is (not (util.point-in-rect? 30 10 0 0 20 20)))))

(deftest positions-equal-test
  (testing "positions-equal?"
    (assert-is (util.positions-equal? {:row 1 :col 2} {:row 1 :col 2}))
    (assert-is (not (util.positions-equal? {:row 1 :col 2} {:row 2 :col 2})))))

(deftest shuffle-test
  (testing "shuffle! preserves elements"
    (let [items [1 2 3 4]
          copy [1 2 3 4]]
      (util.shuffle! items)
      (table.sort items)
      (assert-eq copy items))))
