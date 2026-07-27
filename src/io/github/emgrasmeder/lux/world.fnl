(local internal (require :io.github.emgrasmeder.lux.internal))
(local component-store (require :io.github.emgrasmeder.lux.component-store))
(local unpack internal.unpack)
(local push internal.push)
(local slice internal.slice)
(local get-genid internal.get-genid)
(local all internal.all)

(fn create [component-specs]
  "creates a world with component stores
  component-specs should map component-store name to params
  
  e.g. {:some-component-store-name {:some-param :some-other-param}}"
  (let [genid {:component (get-genid)
               :entity (get-genid)}
        world {:entities {}
               :component-stores {}
               :genid genid}]
    (each [name params (pairs component-specs)]
      (tset world.component-stores name (component-store.create name params)))
    world))

(fn create-entity [world entity]
  (let [id (world.genid.entity)
        component-names {}
        entity-definition-count (# entity)]
    (var i 1)
    (var done nil)
    (var store nil)
    (var component-name nil)
    (var component-args [])
    (var remaining-args 0)
    (while (not done)
      (if (not store)
          (do
            (set component-name (. entity i))
            (set store (. world.component-stores component-name))
            (set remaining-args (. store :arity))
            (set i (+ i 1)))

          (> remaining-args 0)
          (do (push component-args (. entity i))
              (set remaining-args (- remaining-args 1))
              (set i (+ i 1)))

          :else
          (do (component-store.create-component store [id (unpack component-args)])
              (tset component-names component-name true)
              (set store nil)
              (set component-name nil)
              (set component-args [])
              (when (> i entity-definition-count)
                (do (set done true))))))
    (tset world.entities id component-names)
    id))

(fn get-by-id [world entity-id]
  (local component-names (. world.entities entity-id))
  (var result [])
  (each [component-store-name _ (pairs component-names)]
    (let [store (. world.component-stores component-store-name)
          component-data (component-store.get-by-id store entity-id)
          component-data-sans-id (slice component-data 2 (- store.pool-arity 1))]
      (push result component-store-name (unpack component-data-sans-id))))
  result)

(fn get-table-by-id [world entity-id]
  (local component-names (. world.entities entity-id))
  (when component-names
    (var result {})
    (each [component-store-name _ (pairs component-names)]
      (let [store (. world.component-stores component-store-name)
            component-data (component-store.get-by-id store entity-id)
            component-data-sans-id (slice component-data 2 (- store.pool-arity 1))]
        (tset result component-store-name component-data-sans-id)))
    result))

(fn select-entities-with-components [world component-type-names]
  (local results [])
  (each [id entity-components (pairs world.entities)]
    (when (all component-type-names (fn [name] (. entity-components name)))
      (push results id)))
  results)

(fn run-updates [world components-updates]
  (each [component-name component-updates (pairs components-updates)]
    (component-store.run-updates (. (. world :component-stores) component-name)
                                 component-updates)))

(fn run-removals [world entity-removals]
  (let [entities world.entities
        stores-requiring-removals {}]
    (each [id _ (pairs entity-removals)]
      (local components-set (. entities id))
      (each [component-name _ (pairs components-set)]
        (or (. stores-requiring-removals component-name)
            (tset stores-requiring-removals component-name true)))
      (tset entities id nil))
    (each [component-name _ (pairs stores-requiring-removals)]
      (local store (. world.component-stores component-name))
      (component-store.run-removals store entity-removals))))

(fn run-creations [world new-entities]
  (local ids [])
  (for [i 1 (# new-entities)]
    (push ids (create-entity world (. new-entities i))))
  ids)

(fn empty [world]
  (each [_ store (pairs world.component-stores)]
    (component-store.empty store))
  (tset world :entities []))

(fn call-on-common-components [world component-names fun extra-arg]
  (component-store.call-on-common-components
   fun extra-arg
   (do (local stores [])
       (for [i 1 (# component-names)]
         (push stores (. world.component-stores (. component-names i))))
       stores)))

{:create create
 :create-entity create-entity
 :get-by-id get-by-id
 :get-table-by-id get-table-by-id
 :select-entities-with-components select-entities-with-components
 :run-updates run-updates
 :run-removals run-removals
 :run-creations run-creations
 :empty empty
 :call-on-common-components call-on-common-components}
