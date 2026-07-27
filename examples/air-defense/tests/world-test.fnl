(import-macros
 {: deftest : assert-eq : assert-is : testing}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local c (require :constants))
(local lux-world (require :io.github.emgrasmeder.lux.world))
(local get-table-by-id (. lux-world :get-table-by-id))
(local select-entities (. lux-world :select-entities-with-components))

(fn count-select [ids]
  (var n 0)
  (each [_ _ (ipairs ids)]
    (set n (+ n 1)))
  n)

(deftest create-game-world-test
  (testing "world has turret and five buildings at full hp"
    (let [game (world.create-game-world)]
      (assert-is game.world)
      (assert-is game.turret-id)
      (assert-eq c.BUILDING-COUNT (# game.building-ids))
      (each [_ bid (ipairs game.building-ids)]
        (let [b (get-table-by-id game.world bid)]
          (assert-eq :building (. b.actor 1))
          (assert-eq c.MAX-HP (. b.hp 1))))
      (let [t (get-table-by-id game.world game.turret-id)]
        (assert-eq :turret (. t.actor 1))))))

(deftest building-positions-test
  (testing "buildings sit on ground band"
    (each [_ pos (ipairs (world.building-positions))]
      (assert-is (>= (. pos :y) (- c.GROUND-Y c.BUILDING-H))))))

(deftest select-finds-seeded-planes-test
  (testing "lux select-entities sees all seeded planes"
    (let [game (world.create-game-world)
          w game.world
          plane-ids (select-entities w [:actor :team :position :heading :hp :plane-ai])
          red-ids []]
      (assert-eq 10 (count-select plane-ids))
      (each [_ id (ipairs plane-ids)]
        (let [comps (get-table-by-id w id)]
          (when (= (. comps.team 1) :red)
            (table.insert red-ids id))))
      (assert-eq c.RED-MIN (length red-ids)))))

(deftest seeded-reds-on-screen-test
  (testing "initial reds spawn on-screen for immediate turret engagement"
    (math.randomseed 42)
    (let [game (world.create-game-world)
          w game.world
          red-ids []]
      (each [id _ (pairs w.entities)]
        (let [comps (get-table-by-id w id)]
          (when (and comps (= (. comps.actor 1) :plane) (= (. comps.team 1) :red)
                     (> (. comps.hp 1) 0))
            (table.insert red-ids id))))
      (assert-eq c.RED-MIN (length red-ids))
      (each [_ id (ipairs red-ids)]
        (let [[x _y] (. (get-table-by-id w id) :position)]
          (assert-is (>= x 0))
          (assert-is (<= x c.WINDOW-W)))))))
