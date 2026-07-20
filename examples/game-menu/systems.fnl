(local world-api (. (require :io.github.emgrasmeder.lux) :world))
(local get-table-by-id (. world-api :get-table-by-id))

(fn point-in-button? [mx my x y w h]
  (and (>= mx x) (< mx (+ x w))
       (>= my y) (< my (+ y h))))

(fn entity-components [world entity-id]
  (get-table-by-id world entity-id))

(fn hit-test-at [menu mx my]
  (let [world menu.world
        button-ids menu.button-ids]
    (var result nil)
    (each [_ id (ipairs button-ids)]
      (let [components (entity-components world id)]
        (when components
          (let [[x y w h] components.button]
            (when (point-in-button? mx my x y w h)
              (set result id))))))
    result))

(fn focus-next [index count]
  (if (>= index count) 1 (+ index 1)))

(fn focus-prev [index count]
  (if (<= index 1) count (- index 1)))

(fn dispatch-action [kind callbacks]
  (case kind
    :play ((. callbacks :play))
    :exit ((. callbacks :exit))))

(fn action-for-entity [world entity-id]
  (let [components (entity-components world entity-id)]
    (when components (. components.action 1))))

(fn activate-entity [world entity-id callbacks]
  (let [kind (action-for-entity world entity-id)]
    (when kind (dispatch-action kind callbacks))))

(fn handle-click [menu callbacks mx my]
  (let [entity-id (hit-test-at menu mx my)]
    (when entity-id
      (activate-entity menu.world entity-id callbacks))))

(fn handle-key [menu state callbacks key]
  (let [button-count (# menu.button-ids)]
    (case key
      "up" (tset state :focused-index (focus-prev state.focused-index button-count))
      "down" (tset state :focused-index (focus-next state.focused-index button-count))
      ("return" "space") (activate-entity menu.world
                                          (. menu.button-ids state.focused-index)
                                          callbacks)
      "escape" (dispatch-action :exit callbacks))))

{:point-in-button? point-in-button?
 :hit-test-at hit-test-at
 :focus-next focus-next
 :focus-prev focus-prev
 :dispatch-action dispatch-action
 :action-for-entity action-for-entity
 :activate-entity activate-entity
 :handle-click handle-click
 :handle-key handle-key}
