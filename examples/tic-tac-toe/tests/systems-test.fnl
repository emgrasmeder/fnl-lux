(import-macros
 {: deftest : assert-eq : assert-is : assert-not : testing}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local systems (require :systems))

(fn fresh-game []
  (world.create-game-world))

(fn play [game player row col]
  (systems.apply-move game player row col))

(fn board [game]
  (systems.format-board-line game.world game.cell-at))

(deftest valid-move-test
  (testing "apply-move accepts open cells"
    (let [game (fresh-game)]
      (assert-eq true (play game :X 1 1))
      (assert-is (string.find (board game) "1,1: X")))))

(deftest invalid-move-test
  (testing "apply-move rejects bad moves"
    (let [game (fresh-game)]
      (play game :X 1 1)
      (assert-eq false (play game :O 1 1) "occupied")
      (assert-eq false (play game :O 0 1) "out of range row")
      (assert-eq false (play game :O 4 4) "out of range")
      (assert-is (string.find (board game) "1,1: X"))
      (assert-not (string.find (board game) "1,1: O")))))

(deftest no-false-win-test
  (testing "winner on empty or partial board"
    (let [empty (fresh-game)
          started (fresh-game)]
      (play started :X 1 1)
      (assert-eq nil (systems.winner empty))
      (assert-eq nil (systems.winner started)))))

(deftest row-win-test
  (testing "row winner"
    (let [game (fresh-game)]
      (play game :X 1 1)
      (play game :O 2 2)
      (play game :X 1 2)
      (play game :O 2 1)
      (play game :X 1 3)
      (assert-eq :X (systems.winner game)))))

(deftest column-win-test
  (testing "column winner"
    (let [game (fresh-game)]
      (play game :O 1 1)
      (play game :X 2 2)
      (play game :O 2 1)
      (play game :X 3 3)
      (play game :O 3 1)
      (assert-eq :O (systems.winner game)))))

(deftest diagonal-win-test
  (testing "diagonal winner"
    (let [game (fresh-game)]
      (play game :X 1 1)
      (play game :O 1 2)
      (play game :X 2 2)
      (play game :O 1 3)
      (play game :X 3 3)
      (assert-eq :X (systems.winner game)))))

(deftest draw-test
  (testing "full board without winner"
    (let [game (fresh-game)]
      (play game :X 1 1)
      (play game :O 2 2)
      (play game :X 1 3)
      (play game :O 1 2)
      (play game :X 2 1)
      (play game :O 2 3)
      (play game :X 3 2)
      (play game :O 3 1)
      (play game :X 3 3)
      (assert-eq nil (systems.winner game))
      (assert-eq true (systems.draw? game)))))

(deftest hit-test-inside-test
  (testing "hit-test-at inside cell"
    (let [game (fresh-game)
          [x y w h] (world.cell-bounds-at 1 1)
          mx (+ x (/ w 2))
          my (+ y (/ h 2))
          hit (systems.hit-test-at game mx my)]
      (assert-is hit)
      (assert-eq 1 hit.row)
      (assert-eq 1 hit.col))))

(deftest hit-test-outside-test
  (testing "hit-test-at outside board"
    (let [game (fresh-game)]
      (assert-not (systems.hit-test-at game 0 0))
      (assert-not (systems.hit-test-at game 999 999)))))

(deftest format-board-line-test
  (testing "board line format"
    (let [game (fresh-game)
          line (board game)]
      (assert-is (= (string.sub line 1 1) "("))
      (assert-is (line:find "1,1:"))
      (assert-is (line:find "1,2:"))
      (assert-is (line:find "1,3:"))
      (assert-is (line:find "2,1:"))
      (assert-is (line:find "3,3:"))
      (assert-is (< (line:find "1,1:") (line:find "1,2:")))
      (assert-is (< (line:find "1,2:") (line:find "1,3:")))
      (assert-is (< (line:find "1,3:") (line:find "2,1:"))))))
