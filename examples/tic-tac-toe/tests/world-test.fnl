(import-macros
 {: deftest : assert-eq : assert-is : testing}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local systems (require :systems))
(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local get-table-by-id (. world-api :get-table-by-id))

(fn entity-components [game entity-id]
  (get-table-by-id game.world entity-id))

(fn count-keys [t]
  (var n 0)
  (each [_ _ (pairs t)]
    (set n (+ n 1)))
  n)

(deftest create-game-world-test
  (testing "create-game-world"
    (let [game (world.create-game-world)]
      (assert-is game.world "world table")
      (assert-is game.cell-at "cell-at table"))))

(deftest cell-count-test
  (testing "nine cells"
    (let [game (world.create-game-world)]
      (assert-eq 9 (count-keys game.cell-at))
      (assert-eq "1,1" (world.cell-key 1 1))
      (assert-eq "3,3" (world.cell-key 3 3)))))

(deftest initial-board-test
  (testing "empty board display"
    (let [game (world.create-game-world)
          line (systems.format-board-line game.world game.cell-at)]
      (assert-is (line:find "1,1: %[%]") "top-left empty")
      (assert-is (line:find "3,3: %[%]") "bottom-right empty")
      (assert-is (not (line:find "1,1: X")) "no marks yet"))))

(deftest cell-bounds-test
  (testing "cell components"
    (let [game (world.create-game-world)
          entity-id (. game.cell-at (world.cell-key 1 1))
          components (entity-components game entity-id)
          [x y w h] components.cell-bounds]
      (assert-eq world.board-ox x)
      (assert-eq world.board-oy y)
      (assert-eq world.cell-size w)
      (assert-eq world.cell-size h)
      (assert-eq :empty (. components.mark 1)))))
