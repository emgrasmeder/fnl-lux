(import-macros
 {: deftest : assert-eq : assert-is : assert-not : testing}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local systems (require :systems))

(fn fresh-game []
  (world.create-game-world))

(fn cell-center [row col]
  (let [[x y w h] (world.cell-bounds-at row col)]
    [(+ x (/ w 2)) (+ y (/ h 2))]))

(fn playing-state [player]
  {:current-player player :phase :playing})

(deftest handle-click-applies-move-test
  (testing "handle-click applies move at cell center"
    (let [game (fresh-game)
          state (playing-state :X)
          [mx my] (cell-center 1 1)
          outcome (systems.handle-click game state mx my)]
      (assert-is outcome)
      (assert-eq :continue (. outcome :result))
      (assert-eq :O (. outcome :next-player))
      (assert-is (string.find (systems.format-board-line game.world game.cell-at)
                              "1,1: X")))))

(deftest handle-click-occupied-test
  (testing "handle-click rejects occupied cell"
    (let [game (fresh-game)
          state (playing-state :O)
          [mx my] (cell-center 1 1)]
      (systems.apply-move game :X 1 1)
      (assert-not (systems.handle-click game state mx my)))))

(deftest handle-click-outside-test
  (testing "handle-click ignores clicks outside board"
    (let [game (fresh-game)
          state (playing-state :X)]
      (assert-not (systems.handle-click game state 0 0))
      (assert-not (systems.handle-click game state 999 999)))))

(deftest handle-click-win-test
  (testing "handle-click detects row win"
    (let [game (fresh-game)]
      (systems.apply-move game :X 1 1)
      (systems.apply-move game :O 2 2)
      (systems.apply-move game :X 1 2)
      (systems.apply-move game :O 2 1)
      (let [state (playing-state :X)
            [mx my] (cell-center 1 3)
            outcome (systems.handle-click game state mx my)]
        (assert-is outcome)
        (assert-eq :win (. outcome :result))
        (assert-eq :X (. outcome :winner))))))
