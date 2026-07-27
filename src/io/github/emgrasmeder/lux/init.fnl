(local world-api (require :io.github.emgrasmeder.lux.world))
(local component-store (require :io.github.emgrasmeder.lux.component-store))

(fn hello [] 123)

{
 :world world-api

 :world/create world-api.create
 :world/create-entity world-api.create-entity
 :world/get-by-id world-api.get-by-id
 :world/get-table-by-id world-api.get-table-by-id
 :world/select-entities-with-components world-api.select-entities-with-components
 :world/run-updates world-api.run-updates
 :world/run-removals world-api.run-removals
 :world/run-creations world-api.run-creations
 :world/empty world-api.empty
 :world/call-on-common-components world-api.call-on-common-components

 :hello hello

 :__internal__
 {:component-store {:create component-store.create
                    :pool-size component-store.pool-size
                    :count component-store.count
                    :get-by-id component-store.get-by-id
                    :empty component-store.empty
                    :create-component component-store.create-component
                    :run-updates component-store.run-updates
                    :run-removals component-store.run-removals
                    :call-on-common-components component-store.call-on-common-components
                    :get-at component-store.get-at
                    :last-component-pool-position component-store.last-component-pool-position}}}
