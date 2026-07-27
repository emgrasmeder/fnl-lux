(local internal (require :io.github.emgrasmeder.lux.internal))
(local unpack internal.unpack)
(local push internal.push)
(local push-at internal.push-at)
(local slice internal.slice)

(local fennelview (require :fennel.view))
(local inspect fennelview)

(fn pool-size [store] store.pool-size)

(fn count [store]
  (math.floor (/ (pool-size store) store.pool-arity)))

(fn view [store]
   (.. "#<component-store"
       " :name " store.name
       " :params " (inspect store.params)
       " :count " (count store)
       " :real-count " (/ (# store.pool) store.pool-arity)
       ">"))

(fn create [name params]
  "creates a new component-store
  
  params should be an array of argument labels"
  (let [arity (# params)
        pool-arity (+ arity 1)
        name (or name "(anonymous)")]
    {:name name
     :params params
     :arity arity
     :pool-arity pool-arity
     :pool-size 0
     :pool []
     :__inspect__ view}))

(fn last-component-pool-position [store] (+ 1 (- (pool-size store) store.pool-arity)))

(fn pool-position-from-index [store index] (+ 1 (* (- index 1) store.pool-arity)))

(fn get-id-at [store component-index]
  (let [pool-index (pool-position-from-index store component-index)]
    (. store.pool pool-index)))

(fn get-at-pool-position [store pool-index]
  (slice store.pool pool-index store.pool-arity))

(fn get-at [store component-index]
  (let [pool-index (+ 1 (* (- component-index 1) store.pool-arity))]
    (get-at-pool-position store pool-index)))

(fn get-by-id [store id]
  (var i 1)
  (var result nil)
  (var done nil)
  (while (not done)
    (local id-here (. store.pool i))
    (when (= id-here id)
      (set result (get-at-pool-position store i))
      (set done true))
    (set i (+ i store.pool-arity))
    (when (or (= id-here nil) (> id-here id))
      (set done true)))
  result)

(fn empty [store] (tset store :pool []))

(fn create-component [store args]
  (let [original-count (pool-size store)]
    (set store.pool-size (+ original-count store.pool-arity))
    (for [i 1 store.pool-arity]
      (tset store.pool (+ original-count i) (. args i)))))

(fn run-updates [store entities-to-update]
  (let [pool store.pool
        pool-arity store.pool-arity
        arity store.arity]
    (for [i 1 (# pool) pool-arity]
      (local entity-update (. entities-to-update (. pool i)))
      (when entity-update
        (for [j 1 arity]
          (local val (. entity-update j))
          (when (~= val nil) (tset pool (+ i j) val)))))))

(fn run-removals [store entities-to-remove]
  (let [pool store.pool
        pool-arity store.pool-arity
        pool-size (pool-size store)
        i-of-last-id (+ 1 (- pool-size pool-arity))]

    (for [i 1 pool-size pool-arity]
      (when (. entities-to-remove (. pool i))
        (set store.pool-size (- store.pool-size pool-arity))
        (tset pool i nil)))

    (var done nil)
    (var i 1)
    (var copy-from-i nil)
    (while (not done)
      (local it (. pool i))
      (when (= it nil)
        (when (not copy-from-i)
          (set copy-from-i i))
        (var j (+ copy-from-i pool-arity))
        (set copy-from-i nil)
        (while (and (<= j i-of-last-id) (not copy-from-i))
          (when (. pool j) (set copy-from-i j))
          (set j (+ j pool-arity)))

        (when (not copy-from-i)
          (for [j i pool-size]
            (tset pool j nil))
          (set done true))

        (when copy-from-i
          (for [j 0 (- pool-arity 1)]
            (tset pool (+ i j) (. pool (+ copy-from-i j))))
          (tset pool copy-from-i nil)))
      (set i (+ i pool-arity)))))

(fn call-on-common-components [fun static-argument component-stores should-debug]
  (let [num-stores (# component-stores)
        end-indices []
        indices []
        ids []]

    (for [i 1 num-stores]
      (push indices 1)
      (push end-indices (+ 1 (count (. component-stores i)))))

    (var done nil)
    (var all-identical true)
    (var entity-id nil)
    (while (not done)

      (set all-identical true)
      (set entity-id nil)
      (for [i 1 num-stores]
        (let [store (. component-stores i)
              index (. indices i)
              this-id (get-id-at store index)]
          (tset ids i this-id)
          (when (not entity-id) (set entity-id this-id))
          (when (~= this-id entity-id) (set all-identical false))))

      (if
       (and all-identical entity-id)
       (let [components []]
         (for [i 1 num-stores]
           (let [store (. component-stores i)
                 index (. indices i)]
             (push components (get-at store index))
             (tset indices i (+ index 1))))
         (fun static-argument (unpack components)))

       :else
       (do
         (var i num-stores)
         (var increased-an-index false)
         (while (not increased-an-index)
           (if (> i 1)
               (let [index (. indices i)
                     next-index (. indices (- i 1))
                     id-at-index (. ids i)
                     id-at-next-index (. ids (- i 1))]
                 (when (< id-at-index id-at-next-index)
                   (let [store (. component-stores i)]
                     (tset indices i (+ index 1))
                     (set increased-an-index true))))

               :else
               (let [index (. indices i)
                     stores (. component-stores i)]
                 (tset indices i (+ index 1))
                 (set increased-an-index true)))
           (set i (- i 1)))))

      (for [i 1 num-stores]
        (when (and (not done) (>= (. indices i) (. end-indices i)))
          (set done true))))))

{:create create
 :pool-size pool-size
 :count count
 :get-by-id get-by-id
 :empty empty
 :create-component create-component
 :run-updates run-updates
 :run-removals run-removals
 :call-on-common-components call-on-common-components
 :get-at get-at
 :last-component-pool-position last-component-pool-position
 :get-id-at get-id-at
 :get-at-pool-position get-at-pool-position
 :pool-position-from-index pool-position-from-index}
