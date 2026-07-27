(import-macros
 {: deftest : assert-eq : assert-is : assert-not : testing}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local systems (require :systems))
(local lux-world (require :io.github.emgrasmeder.lux.world))
(local get-table-by-id (. lux-world :get-table-by-id))

(fn fresh-menu []
  (world.create-menu-world))

(deftest hit-test-inside-test
  (testing "hit-test-at inside button"
    (let [menu (fresh-menu)
          play-id (. menu.button-ids 1)
          play-components (get-table-by-id menu.world play-id)
          [x y w h] play-components.button
          center-x (+ x (/ w 2))
          center-y (+ y (/ h 2))]
      (assert-eq play-id (systems.hit-test-at menu center-x center-y)))))

(deftest hit-test-outside-test
  (testing "hit-test-at outside buttons"
    (let [menu (fresh-menu)]
      (assert-not (systems.hit-test-at menu 0 0))
      (assert-not (systems.hit-test-at menu 999 999)))))

(deftest focus-next-test
  (testing "focus-next wraps"
    (assert-eq 2 (systems.focus-next 1 2))
    (assert-eq 1 (systems.focus-next 2 2))))

(deftest focus-prev-test
  (testing "focus-prev wraps"
    (assert-eq 1 (systems.focus-prev 2 2))
    (assert-eq 2 (systems.focus-prev 1 2))))

(deftest dispatch-action-test
  (testing "dispatch-action calls callbacks"
    (var played false)
    (var exited false)
    (let [callbacks {:play (fn [] (set played true))
                     :exit (fn [] (set exited true))}]
      (systems.dispatch-action :play callbacks)
      (assert-eq true played)
      (assert-eq false exited)
      (systems.dispatch-action :exit callbacks)
      (assert-eq true exited))))

(deftest point-in-button-test
  (testing "point-in-button?"
    (assert-eq true (systems.point-in-button? 10 10 0 0 20 20))
    (assert-eq false (systems.point-in-button? 30 10 0 0 20 20))))
