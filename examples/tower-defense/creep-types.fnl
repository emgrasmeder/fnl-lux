(local types
  {:base {:escape-cost 10}})

(fn get [type-id]
  (. types (or type-id :base)))

(fn escape-cost [type-id]
  (or (. (get type-id) :escape-cost) 10))

{:types types
 :get get
 :escape-cost escape-cost}
