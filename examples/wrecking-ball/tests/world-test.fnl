(import-macros
 {: deftest : testing : assert-is : assert-eq}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local lux-world (require :io.github.emgrasmeder.lux.world))
(local get-table-by-id (. lux-world :get-table-by-id))
(local c (require :constants))

(deftest create-game-world-test
  (testing "create-game-world"
    (math.randomseed 5)
    (let [game (world.create-game-world 5)]
      (assert-is (. game :world))
      (assert-is (. game :physics))
      (assert-is (. game :score))
      (assert-is (> (# (. game :brick-ids)) 0))
      (assert-is (<= (# (. game :brick-ids)) c.MAX-BRICKS)))))

(deftest brick-components-test
  (testing "brick entities carry color and building metadata"
    (math.randomseed 5)
    (let [game (world.create-game-world 5)
          id (. (. game :brick-ids) 1)
          comp (get-table-by-id (. game :world) id)]
      (assert-eq :brick (. comp.actor 1))
      (assert-is (. comp.brick-color 1))
      (assert-is (. comp.brick-meta 1))
      (assert-is (not comp.position))
      (assert-is (not comp.velocity)))))
