(import-macros
 {: deftest : assert-eq : assert-is : assert-not : testing}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local get-table-by-id (. world-api :get-table-by-id))

(fn count-keys [t]
  (var n 0)
  (each [_ _ (pairs t)]
    (set n (+ n 1)))
  n)

(fn count-walls [terrain grid-w grid-h]
  (var n 0)
  (for [row 1 grid-h]
    (for [col 1 grid-w]
      (when (= (. terrain (world.cell-key row col)) :wall)
        (set n (+ n 1)))))
  n)

(deftest cell-key-test
  (testing "cell-key format"
    (assert-eq "1,1" (world.cell-key 1 1))
    (assert-eq "15,15" (world.cell-key 15 15))))

(deftest generate-terrain-connected-test
  (testing "generated terrain stays connected"
    (math.randomseed 42)
    (for [i 1 10]
      (let [terrain (world.generate-terrain world.GRID-W world.GRID-H world.WALL-DENSITY)]
        (assert-is (world.connected? terrain world.GRID-W world.GRID-H))))))

(deftest wall-density-test
  (testing "wall density is roughly target"
    (math.randomseed 99)
    (let [terrain (world.generate-terrain world.GRID-W world.GRID-H world.WALL-DENSITY)
          walls (count-walls terrain world.GRID-W world.GRID-H)
          target (math.floor (* world.GRID-W world.GRID-H world.WALL-DENSITY))]
      (assert-is (>= walls (- target 5)))
      (assert-is (<= walls (+ target 5))))))

(deftest create-game-world-test
  (testing "create-game-world"
    (math.randomseed 7)
    (let [game (world.create-game-world)]
      (assert-is game.world)
      (assert-is game.cell-at)
      (assert-is game.monster-id)
      (assert-is game.goal-id)
      (assert-eq (* world.GRID-W world.GRID-H) (count-keys game.cell-at)))))

(deftest actor-placement-test
  (testing "monster and goal on distinct empty cells"
    (math.randomseed 7)
    (let [game (world.create-game-world)
          monster (get-table-by-id game.world game.monster-id)
          goal (get-table-by-id game.world game.goal-id)
          [mr mc] monster.position
          [gr gc] goal.position
          monster-cell (. game.cell-at (world.cell-key mr mc))
          goal-cell (. game.cell-at (world.cell-key gr gc))
          monster-terrain (get-table-by-id game.world monster-cell)
          goal-terrain (get-table-by-id game.world goal-cell)]
      (assert-not (= game.monster-id game.goal-id))
      (assert-eq :empty (. monster-terrain.terrain 1))
      (assert-eq :empty (. goal-terrain.terrain 1))
      (assert-eq :monster (. monster.actor 1))
      (assert-eq :goal (. goal.actor 1)))))

(deftest empty-cells-test
  (testing "empty-cells excludes walls"
    (let [terrain (world.generate-terrain 5 5 0.2)
          cells (world.empty-cells terrain 5 5)]
      (each [_ cell (ipairs cells)]
        (assert-eq :empty (. terrain (world.cell-key (. cell :row) (. cell :col))))))))
