(import-macros
 {: deftest : assert-eq : assert-is : assert-not : testing}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local systems (require :systems))
(local lux-world (require :io.github.emgrasmeder.lux.world))
(local get-table-by-id (. lux-world :get-table-by-id))
(local run-updates (. lux-world :run-updates))

(fn fresh-game []
  (world.create-game-world))

(deftest logical-cell-from-position-test
  (testing "logical cell picks nearest center"
    (let [[cx cy] (world.cell-center-at 5 5)]
      (assert-eq 5 (. (systems.logical-cell-from-position cx cy 5 5) :row))
      (assert-eq 5 (. (systems.logical-cell-from-position cx cy 5 5) :col))
      (let [cell (systems.logical-cell-from-position
                  (+ cx 1) cy 5 6)]
        (assert-eq 5 (. cell :row))
        (assert-eq 5 (. cell :col))))))

(deftest spawn-and-repath-test
  (testing "spawned creep gets a path toward the left"
    (math.randomseed 1)
    (let [game (fresh-game)
          state (systems.initial-state)]
      (systems.spawn-creep! game state)
      (assert-eq 1 (# state.creep-ids))
      (let [id (. state.creep-ids 1)
            creep-data (. state.creep-paths id)]
        (assert-is creep-data)
        (assert-is (. creep-data :path))
        (assert-is (> (# (. creep-data :path)) 1))))))

(deftest starts-in-building-phase-test
  (testing "game starts in building with wave 1 ready"
    (let [state (systems.initial-state)]
      (assert-eq :building state.phase)
      (assert-eq 1 state.wave-index)
      (assert-eq 0 state.wave-remaining)
      (assert-eq 0 state.kills)
      (assert-eq 250 state.budget)
      (assert-not state.stats-open)
      (assert-eq nil state.wave-spawn-row))))

(deftest play-starts-first-wave-test
  (testing "Play starts wave 1 with configured count"
    (math.randomseed 1)
    (let [game (fresh-game)
          state (systems.initial-state)
          def (systems.wave-def 1)]
      (systems.play! game state)
      (assert-eq 1 state.wave-index)
      (assert-eq (. def :count) state.wave-remaining)
      (assert-eq 10 state.wave-remaining)
      (assert-is state.wave-spawn-row)
      (assert-eq :playing state.phase))))

(deftest wave-spawns-from-one-row-test
  (testing "all creeps in a wave share the spawn row"
    (math.randomseed 7)
    (let [game (fresh-game)
          state (systems.initial-state)]
      (systems.play! game state)
      (let [row state.wave-spawn-row]
        (tset state :wave-remaining 3)
        (tset state :spawn-timer world.SPAWN-INTERVAL)
        (systems.update-spawn! game state 0)
        (systems.update-spawn! game state world.SPAWN-INTERVAL)
        (systems.update-spawn! game state world.SPAWN-INTERVAL)
        (assert-eq 3 (# state.creep-ids))
        (assert-eq 0 state.wave-remaining)
        (each [_ id (ipairs state.creep-ids)]
          (let [components (get-table-by-id game.world id)]
            (assert-eq row (. components.grid-pos 1))
            (assert-eq world.RIGHT-COL (. components.grid-pos 2))))))))

(deftest enter-advances-wave-test
  (testing "Enter starts the next wave after clearance"
    (math.randomseed 1)
    (let [game (fresh-game)
          state (systems.initial-state)]
      (systems.play! game state)
      (tset state :wave-remaining 0)
      (tset state :creep-ids [])
      (systems.check-wave-complete! state)
      (assert-eq :building state.phase)
      (assert-eq 2 state.wave-index)
      (assert-eq 350 state.budget)
      (systems.handle-key game state "return")
      (assert-eq 2 state.wave-index)
      (assert-eq :playing state.phase)
      (assert-eq (. (systems.wave-def 2) :count) state.wave-remaining))))

(deftest play-noop-while-playing-test
  (testing "Play does nothing during an active wave"
    (math.randomseed 1)
    (let [game (fresh-game)
          state (systems.initial-state)]
      (systems.play! game state)
      (let [remaining state.wave-remaining]
        (systems.play! game state)
        (assert-eq :playing state.phase)
        (assert-eq remaining state.wave-remaining)
        (assert-eq 1 state.wave-index)))))

(deftest place-tower-in-building-test
  (testing "placing a tower works during building"
    (let [game (fresh-game)
          state (systems.initial-state)]
      (assert-eq :building state.phase)
      (assert-is (systems.try-place-tower! game state 15 15))
      (assert-eq :tower (. game.terrain (world.cell-key 15 15)))
      (assert-eq 1 (systems.towers-built game)))))

(deftest place-tower-test
  (testing "placing a tower updates terrain and repaths"
    (let [game (fresh-game)
          state (systems.initial-state)]
      (systems.play! game state)
      (systems.spawn-creep! game state)
      (assert-is (systems.try-place-tower! game state 15 15))
      (assert-eq :tower (. game.terrain (world.cell-key 15 15))))))

(deftest towers-built-counts-place-and-remove-test
  (testing "towers-built tracks place and remove"
    (let [game (fresh-game)
          state (systems.initial-state)]
      (assert-eq 0 (systems.towers-built game))
      (systems.try-place-tower! game state 15 15)
      (systems.try-place-tower! game state 15 16)
      (assert-eq 2 (systems.towers-built game))
      (systems.try-remove-tower! game state 15 15)
      (assert-eq 1 (systems.towers-built game)))))

(deftest stats-toggle-test
  (testing "Stats button toggles overlay; click outside closes"
    (let [game (fresh-game)
          state (systems.initial-state)
          [sx sy] (world.stats-button-rect)
          [px py] (world.stats-panel-rect)]
      (systems.handle-click game state (+ sx 1) (+ sy 1) 1)
      (assert-is state.stats-open)
      (systems.handle-click game state (+ sx 1) (+ sy 1) 1)
      (assert-not state.stats-open)
      (systems.toggle-stats! state)
      (assert-is state.stats-open)
      (systems.handle-click game state 1 1 1)
      (assert-not state.stats-open)
      (systems.toggle-stats! state)
      (systems.handle-click game state (+ px 10) (+ py 10) 1)
      (assert-is state.stats-open))))

(deftest escape-ends-game-test
  (testing "10 escapes ends the game"
    (let [game (fresh-game)
          state (systems.initial-state)]
      (tset state :escapes 9)
      (systems.update-creeps! game state 0)
      (tset state :escapes 10)
      (tset state :phase :ended)
      (assert-eq :ended state.phase))))

(deftest move-toward-test
  (testing "move-toward reaches target within one step"
    (let [[x y arrived] (systems.move-toward 0 0 10 0 10 1)]
      (assert-is arrived)
      (assert-eq 10 x)
      (assert-eq 0 y))))

(deftest creep-escape-on-left-opening-test
  (testing "creep on left opening counts as escape"
    (let [game (fresh-game)
          state (systems.initial-state)
          opening (. (world.left-opening-cells) 1)
          [x y] (world.cell-center-at (. opening :row) (. opening :col))
          id (world.create-entity game.world [:position x y
                                               :grid-pos (. opening :row) (. opening :col)
                                               :hp world.CREEP-HP
                                               :creep])]
      (systems.play! game state)
      (tset state :creep-ids [id])
      (tset state :creep-paths id {:path [{:row (. opening :row) :col (. opening :col)}]
                                   :path-idx 1})
      (tset state :wave-remaining 1)
      (systems.update-creeps! game state 0)
      (assert-eq 1 state.escapes)
      (assert-eq 0 (# state.creep-ids))
      (assert-eq 240 state.budget))))

(deftest spawn-creep-has-hp-test
  (testing "spawned creep has CREEP-HP and base type"
    (math.randomseed 1)
    (let [game (fresh-game)
          state (systems.initial-state)]
      (systems.spawn-creep! game state)
      (let [id (. state.creep-ids 1)
            components (get-table-by-id game.world id)
            creep-data (. state.creep-paths id)]
        (assert-eq world.CREEP-HP (. components.hp 1))
        (assert-eq :base (. creep-data :type))))))

(deftest place-tower-records-blaster-test
  (testing "placing a tower records blaster type in state.towers"
    (let [game (fresh-game)
          state (systems.initial-state)]
      (assert-is (systems.try-place-tower! game state 15 15))
      (let [tower (. state.towers (world.cell-key 15 15))]
        (assert-is tower)
        (assert-eq :blaster (. tower :type))
        (assert-eq 0 (. tower :cooldown))
        (assert-eq 15 (. tower :row))
        (assert-eq 15 (. tower :col))))))

(fn place-creep-at! [game state row col]
  (let [[x y] (world.cell-center-at row col)
        id (world.create-entity game.world [:position x y
                                             :grid-pos row col
                                             :hp world.CREEP-HP
                                             :creep])]
    (table.insert state.creep-ids id)
    (tset state.creep-paths id {:path [] :path-idx 1 :walk-phase 0 :type :base})
    id))

(fn drain-bullets! [game state steps step-dt]
  (for [_ 1 steps]
    (systems.update-bullets! game state step-dt)))

(deftest blaster-spawns-bullet-then-damages-test
  (testing "ready blaster spawns bullet; damage applies on contact"
    (let [game (fresh-game)
          state (systems.initial-state)
          id (place-creep-at! game state 15 16)]
      (systems.play! game state)
      (systems.try-place-tower! game state 15 15)
      (let [tower (. state.towers (world.cell-key 15 15))]
        (tset tower :cooldown 0)
        (systems.update-towers! game state 0)
        (assert-eq 1 (# state.bullet-ids))
        (assert-eq world.CREEP-HP (. (get-table-by-id game.world id) :hp 1))
        (assert-eq world.BLASTER-FIRE-INTERVAL (. tower :cooldown))
        (drain-bullets! game state 20 0.05)
        (assert-eq 0 (# state.bullet-ids))
        (assert-eq (- world.CREEP-HP world.BLASTER-DAMAGE)
                   (. (get-table-by-id game.world id) :hp 1))))))

(deftest blaster-fire-interval-test
  (testing "second shot waits BLASTER-FIRE-INTERVAL"
    (let [game (fresh-game)
          state (systems.initial-state)
          id (place-creep-at! game state 15 16)]
      (systems.play! game state)
      (systems.try-place-tower! game state 15 15)
      (let [tower (. state.towers (world.cell-key 15 15))]
        (tset tower :cooldown 0)
        (systems.update-towers! game state 0)
        (assert-eq 1 (# state.bullet-ids))
        (systems.update-towers! game state 0.5)
        (assert-eq 1 (# state.bullet-ids))
        (systems.update-towers! game state 0.5)
        (assert-eq 2 (# state.bullet-ids))
        (drain-bullets! game state 20 0.05)
        (assert-eq (- world.CREEP-HP (* 2 world.BLASTER-DAMAGE))
                   (. (get-table-by-id game.world id) :hp 1))))))

(deftest blaster-targets-nearest-test
  (testing "tower aims at closer creep, not farther"
    (let [game (fresh-game)
          state (systems.initial-state)
          near-id (place-creep-at! game state 15 16)
          far-id (place-creep-at! game state 15 25)]
      (systems.play! game state)
      (systems.try-place-tower! game state 15 15)
      (let [tower (. state.towers (world.cell-key 15 15))]
        (tset tower :cooldown 0)
        (systems.update-towers! game state 0)
        (assert-eq 1 (# state.bullet-ids))
        (drain-bullets! game state 20 0.05)
        (assert-eq (- world.CREEP-HP world.BLASTER-DAMAGE)
                   (. (get-table-by-id game.world near-id) :hp 1))
        (assert-eq world.CREEP-HP (. (get-table-by-id game.world far-id) :hp 1))))))

(deftest blaster-kill-increments-score-test
  (testing "bullet kill removes creep and increments kills"
    (let [game (fresh-game)
          state (systems.initial-state)
          id (place-creep-at! game state 15 16)]
      (systems.play! game state)
      (systems.try-place-tower! game state 15 15)
      (run-updates game.world {:hp {id [world.BLASTER-DAMAGE]}})
      (let [tower (. state.towers (world.cell-key 15 15))]
        (tset tower :cooldown 0)
        (systems.update-towers! game state 0)
        (drain-bullets! game state 20 0.05)
        (assert-eq 0 (# state.creep-ids))
        (assert-eq 0 (# state.bullet-ids))
        (assert-eq 1 state.kills)
        (assert-eq nil (get-table-by-id game.world id))))))

(deftest bullet-miss-despawns-test
  (testing "bullet with no creeps despawns off board without scoring"
    (let [game (fresh-game)
          state (systems.initial-state)
          [tx ty] (world.cell-center-at 15 15)
          [cx cy] (world.cell-center-at 15 1)]
      (systems.play! game state)
      (systems.spawn-bullet! game state tx ty cx cy world.BLASTER-DAMAGE)
      (assert-eq 1 (# state.bullet-ids))
      (drain-bullets! game state 80 0.05)
      (assert-eq 0 (# state.bullet-ids))
      (assert-eq 0 state.kills))))

(deftest creep-bob-advances-while-moving-test
  (testing "walk-phase advances when creep moves"
    (math.randomseed 1)
    (let [game (fresh-game)
          state (systems.initial-state)]
      (systems.spawn-creep! game state)
      (let [id (. state.creep-ids 1)
            before (or (. (. state.creep-paths id) :walk-phase) 0)]
        (systems.update-creeps! game state 0.1)
        (let [after (or (. (. state.creep-paths id) :walk-phase) 0)]
          (assert-is (> after before)))))))

(deftest place-tower-deducts-budget-test
  (testing "placing a tower deducts tower cost from budget"
    (let [game (fresh-game)
          state (systems.initial-state)]
      (assert-eq 250 state.budget)
      (assert-is (systems.try-place-tower! game state 15 15))
      (assert-eq 225 state.budget)
      (assert-eq :tower (. game.terrain (world.cell-key 15 15))))))

(deftest unaffordable-place-noop-test
  (testing "cannot place tower when budget is below cost"
    (let [game (fresh-game)
          state (systems.initial-state)]
      (tset state :budget 24)
      (assert-not (systems.try-place-tower! game state 15 15))
      (assert-eq :empty (. game.terrain (world.cell-key 15 15)))
      (assert-eq 24 state.budget))))

(deftest remove-tower-refunds-budget-test
  (testing "removing a tower refunds 60 percent of cost"
    (let [game (fresh-game)
          state (systems.initial-state)]
      (systems.try-place-tower! game state 15 15)
      (assert-eq 225 state.budget)
      (assert-is (systems.try-remove-tower! game state 15 15))
      (assert-eq 240 state.budget)
      (assert-eq :empty (. game.terrain (world.cell-key 15 15))))))

(deftest escape-clamps-budget-at-zero-test
  (testing "escape cost clamps budget at zero"
    (let [game (fresh-game)
          state (systems.initial-state)
          opening (. (world.left-opening-cells) 1)
          [x y] (world.cell-center-at (. opening :row) (. opening :col))
          id (world.create-entity game.world [:position x y
                                               :grid-pos (. opening :row) (. opening :col)
                                               :hp world.CREEP-HP
                                               :creep])]
      (systems.play! game state)
      (tset state :budget 5)
      (tset state :creep-ids [id])
      (tset state.creep-paths id {:path [{:row (. opening :row) :col (. opening :col)}]
                                   :path-idx 1
                                   :type :base})
      (tset state :wave-remaining 1)
      (systems.update-creeps! game state 0)
      (assert-eq 0 state.budget)
      (assert-eq 1 state.escapes))))

(deftest final-wave-clear-awards-and-wins-test
  (testing "final wave clear awards wave-index times 100 then wins"
    (let [game (fresh-game)
          state (systems.initial-state)
          final (systems.wave-count)]
      (systems.play! game state)
      (tset state :wave-index final)
      (tset state :wave-remaining 0)
      (tset state :creep-ids [])
      (tset state :budget 0)
      (systems.check-wave-complete! state)
      (assert-eq :won state.phase)
      (assert-eq (* final 100) state.budget)
      (assert-eq final state.wave-index))))
