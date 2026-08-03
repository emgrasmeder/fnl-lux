(import-macros
 {: deftest : assert-eq : assert-is : assert-not : testing}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))

(deftest terrain-openings-test
  (testing "30x30 board with centered 12-cell openings"
    (let [terrain (world.build-terrain)]
      (var total 0)
      (each [_ _ (pairs terrain)]
        (set total (+ total 1)))
      (assert-eq 900 total)
      (for [row world.OPENING-START-ROW world.OPENING-END-ROW]
        (assert-eq :opening (. terrain (world.cell-key row world.LEFT-COL)))
        (assert-eq :opening (. terrain (world.cell-key row world.RIGHT-COL))))
      (assert-eq :wall (. terrain (world.cell-key 1 1)))
      (assert-eq :wall (. terrain (world.cell-key 9 world.LEFT-COL)))
      (assert-eq :wall (. terrain (world.cell-key 22 world.LEFT-COL))))))

(deftest window-size-test
  (testing "window fits 30x30 grid plus bottom bar"
    (assert-eq 680 (world.window-width))
    (assert-eq 688 (world.window-height))))

(deftest button-rects-test
  (testing "Play and Stats sit below the grid"
    (let [[px py pw ph] (world.play-button-rect)
          [sx sy sw sh] (world.stats-button-rect)
          bottom (world.board-bottom)]
      (assert-is (>= py bottom))
      (assert-is (>= sy bottom))
      (assert-eq world.BUTTON-W pw)
      (assert-eq world.BUTTON-W sw)
      (assert-eq world.BUTTON-H ph)
      (assert-eq world.BUTTON-H sh)
      (assert-is (world.point-in-rect? (+ px 1) (+ py 1) px py pw ph))
      (assert-not (world.point-in-rect? (+ px 1) (+ py 1) sx sy sw sh)))))

(deftest pixel-to-cell-test
  (testing "pixel-to-cell maps board coordinates"
    (let [cell (world.pixel-to-cell world.BOARD-OX world.BOARD-OY)]
      (assert-eq 1 (. cell :row))
      (assert-eq 1 (. cell :col)))))

(deftest create-game-world-test
  (testing "create-game-world"
    (let [game (world.create-game-world)]
      (assert-is game.world)
      (assert-is game.terrain)
      (assert-eq 30 game.grid-w)
      (assert-eq 30 game.grid-h))))
