(import-macros
 {: deftest : testing : assert-is}
 :io.gitlab.andreyorst.fennel-test)

(local c (require :constants))

(fn fixtures-collide? [cat-a mask-a cat-b mask-b]
  (and (not= 0 (band cat-a mask-b))
       (not= 0 (band cat-b mask-a))))

(deftest brick-mask-includes-ball-test
  (testing "brick collide mask includes wrecking ball category"
    (assert-is (not= 0 (band c.MASK-BRICK c.CAT-BALL)))))

(deftest ball-brick-collision-filter-test
  (testing "Box2D filter allows ball and brick to collide both ways"
    (let [ball-mask (+ c.CAT-GROUND c.CAT-BRICK)]
      (assert-is (fixtures-collide? c.CAT-BALL ball-mask c.CAT-BRICK c.MASK-BRICK)))))
