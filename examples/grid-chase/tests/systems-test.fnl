(import-macros
 {: deftest : assert-eq : assert-is : assert-not : testing}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local systems (require :systems))
(local lux-world (require :io.github.emgrasmeder.lux.world))
(local run-updates (. lux-world :run-updates))

(fn empty-terrain []
  (var terrain {})
  (for [row 1 world.GRID-H]
    (for [col 1 world.GRID-W]
      (tset terrain (world.cell-key row col) :empty)))
  terrain)

(fn fresh-game [monster-pos goal-pos]
  (world.create-game-from-terrain (empty-terrain) monster-pos goal-pos))

(deftest initial-path-test
  (testing "initial state has path to goal"
    (let [game (fresh-game {:row 1 :col 1} {:row 1 :col 5})
          state (systems.initial-state game)]
      (assert-is state.path)
      (assert-is (> (# state.path) 0)))))

(deftest step-moves-monster-test
  (testing "step-once moves monster along path"
    (let [game (fresh-game {:row 1 :col 1} {:row 1 :col 3})
          state (systems.initial-state game)
          start (systems.get-actor-position game game.monster-id)]
      (assert-eq 1 (. start :row))
      (assert-eq 1 (. start :col))
      (systems.step-once game state nil)
      (let [after (systems.get-actor-position game game.monster-id)]
        (assert-eq 1 (. after :row))
        (assert-eq 2 (. after :col))
        (assert-eq 1 (# state.path))))))

(deftest catch-relocates-goal-test
  (testing "reaching goal relocates it and replans"
    (let [game (fresh-game {:row 1 :col 1} {:row 1 :col 2})
          state {:path [] :step-timer 0}]
      (run-updates game.world {:position {game.monster-id [1 2]}})
      (var caught 0)
      (systems.step-once game state (fn [] (set caught (+ caught 1))))
      (assert-eq 1 caught)
      (let [monster (systems.get-actor-position game game.monster-id)
            goal (systems.get-actor-position game game.goal-id)]
        (assert-not (systems.positions-equal? monster goal))
        (assert-is state.path)
        (assert-is (> (# state.path) 0))))))

(deftest goal-not-on-monster-test
  (testing "relocate-goal never places goal on monster"
    (math.randomseed 123)
    (let [game (fresh-game {:row 3 :col 3} {:row 3 :col 4})]
      (for [i 1 20]
        (systems.relocate-goal! game)
        (let [monster (systems.get-actor-position game game.monster-id)
              goal (systems.get-actor-position game game.goal-id)]
          (assert-not (systems.positions-equal? monster goal)))))))

(deftest format-grid-line-test
  (testing "format-grid-line shows actors"
    (let [game (fresh-game {:row 1 :col 1} {:row 1 :col 3})
          line (systems.format-grid-line game)]
      (assert-is (line:find "1,1: X"))
      (assert-is (line:find "1,3: O")))))
