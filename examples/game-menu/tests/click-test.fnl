(import-macros
 {: deftest : assert-is : testing}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local systems (require :systems))
(local lux-world (require :io.github.emgrasmeder.lux.world))
(local get-table-by-id (. lux-world :get-table-by-id))

(fn fresh-menu []
  (world.create-menu-world))

(fn button-center [menu index]
  (let [id (. menu.button-ids index)
        components (get-table-by-id menu.world id)
        [x y w h] components.button]
    [(+ x (/ w 2)) (+ y (/ h 2))]))

(deftest handle-click-play-test
  (testing "handle-click on Play invokes play callback"
    (var played false)
    (let [menu (fresh-menu)
          [mx my] (button-center menu 1)]
      (systems.handle-click menu {:play (fn [] (set played true))
                                  :exit (fn [])}
                            mx my)
      (assert-is played))))

(deftest handle-click-exit-test
  (testing "handle-click on Exit invokes exit callback"
    (var exited false)
    (let [menu (fresh-menu)
          [mx my] (button-center menu 2)]
      (systems.handle-click menu {:play (fn [])
                                  :exit (fn [] (set exited true))}
                            mx my)
      (assert-is exited))))
