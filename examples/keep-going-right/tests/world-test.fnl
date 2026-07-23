(import-macros
 {: deftest : testing : assert-is : assert-eq}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local get-table-by-id (. world-api :get-table-by-id))

(deftest create-game-world-test
  (testing "create-game-world"
    (math.randomseed 5)
    (let [game (world.create-game-world)]
      (assert-is game.world)
      (assert-is game.player-id)
      (assert-is game.cam-state)
      (assert-is (. game.cam-state.panes 0)))))

(deftest player-entity-test
  (testing "player has actor and physics components"
    (math.randomseed 5)
    (let [game (world.create-game-world)
          components (get-table-by-id game.world game.player-id)]
      (assert-eq :player (. components.actor 1))
      (assert-is (. components.position 1))
      (assert-is (. components.position 2))
      (assert-eq true (. components.grounded 1)))))
