;; -*- mode: fennel; -*- vi:ft=fennel

(import-macros
 {: deftest : assert-eq : assert-is : testing}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local lux-world (require :io.github.emgrasmeder.lux.world))
(local get-table-by-id (. lux-world :get-table-by-id))

(deftest create-menu-world-test
  (testing "create-menu-world"
    (let [menu (world.create-menu-world)]
      (assert-is menu.world "world table")
      (assert-is menu.button-ids "button-ids table")
      (assert-eq 2 (# menu.button-ids)))))

(deftest play-button-test
  (testing "play button components"
    (let [menu (world.create-menu-world)
          play-id (. menu.button-ids 1)
          components (get-table-by-id menu.world play-id)]
      (assert-eq "Play" (. components.label 1))
      (assert-eq :play (. components.action 1)))))

(deftest exit-button-test
  (testing "exit button components"
    (let [menu (world.create-menu-world)
          exit-id (. menu.button-ids 2)
          components (get-table-by-id menu.world exit-id)]
      (assert-eq "Exit" (. components.label 1))
      (assert-eq :exit (. components.action 1)))))
