(local TOWER-REFUND-RATE 0.6)

(local types
  {:blaster {:cost 25}})

(fn get [type-id]
  (. types (or type-id :blaster)))

(fn cost [type-id]
  (or (. (get type-id) :cost) 25))

(fn refund [type-id]
  (math.floor (* (cost type-id) TOWER-REFUND-RATE)))

{:TOWER-REFUND-RATE TOWER-REFUND-RATE
 :types types
 :get get
 :cost cost
 :refund refund}
