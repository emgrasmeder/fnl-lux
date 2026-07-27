(import-macros
 {: deftest : assert-eq : testing}
 :io.gitlab.andreyorst.fennel-test)

(local lux-world (require :io.github.emgrasmeder.lux.world))
(local create (. lux-world :create))
(local create-entity (. lux-world :create-entity))
(local select-entities (. lux-world :select-entities-with-components))

(fn count-ids [ids]
  (var n 0)
  (each [_ _ (ipairs ids)]
    (set n (+ n 1)))
  n)

(deftest select-entities-with-components-test
  (testing "select returns entities that have every listed component"
    (let [w (create {:actor [:kind] :position [:x :y]})]
      (create-entity w [:actor :sprite :position 10 20])
      (create-entity w [:actor :sprite :position 30 40])
      (assert-eq 2 (count-ids (select-entities w [:actor :position])))
      (assert-eq 0 (count-ids (select-entities w [:actor :position :velocity]))))))
