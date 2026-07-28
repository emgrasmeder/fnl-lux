(import-macros
 {: deftest : testing}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local c (require :constants))
(local systems (require :systems))
(local lux-world (require :io.github.emgrasmeder.lux.world))
(local create (. lux-world :create))
(local create-entity (. lux-world :create-entity))

(fn empty-game []
  (let [w (create world.component-spec)]
    {:world w :turret-id 0 :building-ids []}))

(deftest green-with-no-reds-steps-safely-test
  (testing "green plane with no red targets does not error on step"
    (let [game (empty-game)
          w game.world
          state (systems.initial-state game)]
      (create-entity w [:actor :plane
                        :position 400 200
                        :velocity 0 0
                        :heading 0
                        :hp c.PLANE-HP
                        :team :green
                        :plane-ai :hunt 0 0 0])
      (for [i 1 30]
        (systems.step game state 0.05)))))
