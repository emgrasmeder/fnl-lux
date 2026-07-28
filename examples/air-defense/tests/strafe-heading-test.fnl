(import-macros
 {: deftest : assert-is : testing}
 :io.gitlab.andreyorst.fennel-test)

(local world (require :world))
(local c (require :constants))
(local ai (require :ai))
(local flight (require :flight))
(local lux-world (require :io.github.emgrasmeder.lux.world))
(local create (. lux-world :create))
(local create-entity (. lux-world :create-entity))
(local get-table-by-id (. lux-world :get-table-by-id))

(fn strafe-target-y [w building-id px py]
  (when (ai.strafe-building-desired px py building-id w)
    (let [comps (get-table-by-id w building-id)
          [bx by] comps.position
          d (flight.dist px py bx by)]
      (+ by (if (< d c.STRAFE-CLOSE-DIST) c.STRAFE-APPROACH-Y-NEAR c.STRAFE-APPROACH-Y-FAR)))))

(deftest strafe-aim-stays-above-ground-test
  (testing "red strafe approach points stay above ground line"
    (let [w (create world.component-spec)
          bid (create-entity w [:actor :building
                                :position 400 (- c.GROUND-Y (/ c.BUILDING-H 2))
                                :hp c.MAX-HP])]
      (each [_ [px py] (ipairs [[400 200] [400 450] [350 500]])]
        (let [ty (strafe-target-y w bid px py)]
          (assert-is ty)
          (assert-is (< ty (- c.GROUND-Y c.PLANE-R))))))))
