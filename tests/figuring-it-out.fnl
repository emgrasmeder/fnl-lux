(import-macros
 {: deftest : assert-is : testing}
 :io.gitlab.andreyorst.fennel-test)

(local {: world/create} (require :io.github.emgrasmeder.lux))

(deftest world-create-test
  (testing "world/create makes component stores"
    (let [world (world/create {:position [:x :y]})]
      (assert-is (. world.component-stores :position)))))
