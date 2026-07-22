(import-macros
 {: deftest : assert-eq : assert-is : assert-not : testing}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local get-table-by-id (. world-api :get-table-by-id))

(fn count-walls [game]
  (var n 0)
  (for [row 1 game.grid-h]
    (for [col 1 game.grid-w]
      (let [entity-id (. game.cell-at (world.cell-key row col))
            components (get-table-by-id game.world entity-id)]
        (when (and components (= (. components.terrain 1) :wall))
          (set n (+ n 1))))))
  n)

(fn count-playable [game]
  (var n 0)
  (for [row 1 game.grid-h]
    (for [col 1 game.grid-w]
      (when (world.playable? row col)
        (set n (+ n 1)))))
  n)

(deftest border-wall-count-test
  (testing "20x20 grid has 76 border walls"
    (let [game (world.create-game-world)]
      (assert-eq 76 (count-walls game)))))

(deftest playable-area-test
  (testing "playable interior is 18x18"
    (let [game (world.create-game-world)]
      (assert-eq 324 (count-playable game)))))

(deftest create-game-world-test
  (testing "create-game-world spawns player and food"
    (math.randomseed 7)
    (let [game (world.create-game-world)]
      (assert-is game.world)
      (assert-is game.player-id)
      (assert-is game.food-id)
      (assert-eq 3 (# game.initial-body))
      (assert-is game.initial-direction))))

(deftest food-not-on-snake-at-spawn-test
  (testing "food does not spawn on snake body"
    (math.randomseed 42)
    (for [i 1 20]
      (let [game (world.create-game-world)
            components (get-table-by-id game.world game.food-id)
            food {:row (. components.position 1)
                  :col (. components.position 2)}]
        (assert-not (world.occupied-by-body? game.initial-body (. food :row) (. food :col)))))))

(deftest create-game-from-state-test
  (testing "create-game-from-state uses fixed setup"
    (let [game (world.create-game-from-state [{:row 11 :col 11} {:row 11 :col 10} {:row 11 :col 9}]
                                               {:row 5 :col 5} :right)]
      (assert-eq 3 (# game.initial-body))
      (assert-eq :right game.initial-direction)
      (let [player (get-table-by-id game.world game.player-id)]
        (assert-eq 11 (. player.position 1))
        (assert-eq 11 (. player.position 2))
        (assert-eq :right (. player.direction 1))))))

(deftest body-behind-head-test
  (testing "three-segment body extends opposite direction"
    (let [body (world.body-behind-head 11 11 :right)]
      (assert-eq 3 (# body))
      (assert-eq 11 (. (. body 1) :row))
      (assert-eq 11 (. (. body 1) :col))
      (assert-eq 10 (. (. body 2) :col))
      (assert-eq 9 (. (. body 3) :col)))))
